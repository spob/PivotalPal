# This is a periodic job that only runs one time.
#
# It inherits from the PeriodicJob base class
class RunOncePeriodicJob < PeriodicJob
  before_create :set_next_run

  def self.create_job(name, job, run_at = Time.now)
    RunOncePeriodicJob.create!(:name => name, :job => job, :next_run_at => run_at)
  end

  # It should run right away
  def set_next_run
    self.next_run_at = Time.zone.now unless self.next_run_at
  end

  # Return nil for the next_run_at field, indicating that it should not run again
  def calc_next_run
    self.next_run_at = nil
  end
end
