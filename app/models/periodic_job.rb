# A periodic job represents a background job that will be executed by the task_scheduler.
# this class is the base class, and multiple subclasses (e.g., RunOncePeriodicJobs) inherit
# from it.
#
# A periodic job with a last_run_at is one that has already executed, in which case it's next_run_at
# field should be nil. For jobs waiting to run, the reverse is true.
#
# For jobs which are pending, the last_run_result will be nil.
# For jobs which are currently running, the last_run_result will be 'Running'
# For jobs which have completed their execution, the last_run_result will hold 'OK', or the exception
# message if one occurred
class PeriodicJob < ActiveRecord::Base
  # The subclass will set the next_run_at value depending on the logic appropriate for
  # that type of job
  before_create :set_initial_next_run

  validates_presence_of :name, :job


  # The task scheduler will look for jobs ready to run...specifically, those jobs for which the next_run_at
  # has already passed but have a nil last_run_result, implying that it's not yet started
  def self.ready_to_run now=Time.now
    where(:next_run_at.lt => now, :last_run_result.eq => nil).order("next_run_at ASC").limit(1).lock
  end


  # The task scheduler will periodically check for jobs which are stuck. This could happen, for example,
  # if the task scheduler crashed during execution of the job. This is looking for jobs that are in the
  # process of running and have been doing so for a long time...a long time being a parameter that
  # can be configured in the parameters file.
  def self.zombies
    where(:last_run_at.lt => Time.now - PERIODIC_JOB_TIMEOUT.minutes,
          :next_run_at.eq => nil,
          :last_run_result.eq => 'Running')
  end

# Basic paginated listing finder
#  def self.list(page, per_page)
#    order("next_run_at DESC, last_run_at DESC").page(page).per(per_page)
#  end

# Check for jobs that are hung...and fail the job (which will rerun the job if appropriate
  def self.process_zombies
    puts "checking for zombies..."
    PeriodicJob.transaction do
      for job in PeriodicJob.zombies
        #        puts "Found...#{job.id}"
        log_error("Failed zombie periodic job #{job.id}")
        job.fail_job
      end
    end
    puts "done"
  end

# Retrieve a list of jobs which are ready to run
  def self.find_jobs_to_run
    # first grab all rows that are ready to run...we do this (with a lock)
    # to ensure that other threads or task_schedulers won't try to run
    # the same jobs
    PeriodicJob.transaction do
      jobs = PeriodicJob.ready_to_run.limit(3)

      # Update last_run_result to 'Running' to signal it is in process
      PeriodicJob.where(:id => jobs.collect(&:id)).update_all(:last_run_result => 'Running')
      jobs
    end
  end

# Execute jobs pending to run.
  def self.run_jobs
    running_rake_count = self.write_pid_file
    if running_rake_count > MAX_RUN_JOBS_RAKE_PROCESSES
      log_error "Max rake jobs:run jobs running...exiting"
      return
    else
      log_debug "#{running_rake_count} rakes detected"
    end
    begin
      process_zombies
      jobs_found = false
      begin
        log_debug("Checking for periodic jobs to run...")
        jobs = PeriodicJob.find_jobs_to_run
        jobs.each do |job|
          job.run!
          jobs_found = true
        end
      end while jobs.present?
      jobs_found ? log_debug("Done") : log_debug("No jobs ready to run")
      jobs_found
    ensure
      log_debug "Cleaning up pid file"
      self.write_pid_file true
    end
  end

# Default behavior for calculating the next_run date, which will be generally overriden by the
# subclass (except for the case of a run once job).
# When a job completes, the task scheduler will invoke this method to persist a new instance of
# the job to run based on the value returned by this method. A return value of nil indicates
# that the job should not run again, in which case a new job instance will not be created.
  def calc_next_run
    nil
  end

  def can_delete?
    false
  end

# When a new record is created, calculate the time when it should first run
  def set_initial_next_run
    self.next_run_at = Time.zone.now if self.next_run_at.nil?
  end

# Runs a job and updates the +last_run_at+ field.
  def run!
    PeriodicJob.log_error "Executing job id #{self.id}, #{self.to_s}..."
    begin
      self.last_run_at = Time.now
      self.next_run_at = nil
      self.save
      command = self.job.gsub(/#JOBID#/, self.id.to_s).gsub(/#RAILS_ROOT#/, Rails.root.to_s)
      puts command
      eval(command)
      self.last_run_result = "OK"
      PeriodicJob.log_info "Job completed successfully"
    rescue Exception
      err_string = "'#{self.job}' could not run: #{$!.message}\n#{$!.backtrace}"
      PeriodicJob.log_error err_string
      self.last_run_result = err_string.slice(1..500)
      begin
        GeneralMailer.failed_periodic_job(self).deliver
      rescue
      end
    end
    self.save

    # ...and persist the next run of this job if one exists
    set_next_job
  end

# Mark the current job as Timed out, and rerun it...used to process zombie jobs
  def fail_job
    self.last_run_at = Time.now
    self.next_run_at = nil
    self.last_run_result = "Timeout"
    self.save

    # ...and persist the next run of this job if one exists
    set_next_job
  end

# Cleans up all jobs older than a week.
  def self.cleanup
    self.destroy_all ['last_run_at < ?', KEEP_PERIODIC_JOB_DAYS.day.ago]
  end

  def self.find_by_name_or_create(arg)
    if arg.is_a? String
      where(:next_run_at ^ nil, :name >> arg).first
    elsif arg.is_a? Hash
      where(:next_run_at ^ nil, :name >> arg[:name]).first || create(arg)
    end
  end

  def to_s
    "#{self.class.to_s}: #{job}"
  end

  private

  def set_next_job
    next_job = self.calc_next_run
    next_job.save unless next_job.nil?
  end

  protected

  def self.write_pid_file ending=false
    filepath = "#{File.dirname(__FILE__)}/../../tmp/pids/rake_jobs_run.pid"
#    puts "PID FILE: #{filepath}"
    running_instances = []
    running_instances << $$ unless ending
    # if the pid file exists, read it and check to see which pids are still valid
    if File.exists?(filepath) && File.file?(filepath)
      pid_file = File.open(filepath)
      pid_file.each do |line|
        begin
          Process.kill 0, line.to_i
#          puts "Process exists: #{line}"
          running_instances << line.to_i if !ending || line.to_i != $$
        rescue Errno::ESRCH
#          puts "No such process #{line}"
        end
      end
      pid_file.close
    end

    if running_instances.present?
      # there are running rakes, so rewrite them out to the pid file
      pid_file = File.open(filepath, 'w')
      running_instances.each { |pid| pid_file.puts pid }
      pid_file.close
    else
      # there are no running rakes, delete the pid file
      File.delete(filepath) if File.exists?(filepath) && File.file?(filepath)
    end
    running_instances.size
  end

  def self.log_info str
    puts str unless Rails.env.test?
    TaskServerLogger.instance.info str
  end

  def self.log_error str
    puts str unless Rails.env.test?
    TaskServerLogger.instance.error str
  end

  def self.log_debug str
    puts str unless Rails.env.test?
    TaskServerLogger.instance.debug str
  end
end
