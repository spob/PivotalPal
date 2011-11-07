class Iteration < ActiveRecord::Base
  belongs_to :project, :counter_cache => true
  has_many :stories, :dependent => :destroy
  has_many :task_estimates, :dependent => :destroy
  has_many :tasks, :through => :stories
  has_many :task_estimates, :conditions => {:task_id => nil}, :order => "as_of", :dependent => :destroy
  has_one :latest_estimate, :class_name => "TaskEstimate", :conditions => {:task_id => nil}, :order => "as_of DESC"

  validates_presence_of :iteration_number
  validates_presence_of :start_on
  validates_presence_of :end_on
  # No reason to enforce uniqueness...the database index will handle it for us
  #  validates_uniqueness_of :iteration_number, :scope => :project_id
  validates_numericality_of :iteration_number, :only_integer => true, :allow_blank => true, :greater_than => 0

  scope :last_iteration, lambda { |project|
    where(:project => project).includes(:task_estimates, :stories => {:tasks => :task_estimates}).order("iteration_number desc").limit(1)
  }

  def iteration_name
    "Iteration #{self.iteration_number}"
  end

  def remaining_hours_for_day_number day_number
    if day_number == 0
      self.tasks.find_all { |t| !t.pushed? }.map { |t| t.task_estimates }.flatten.find_all { |e| e.day_number == 1 }.inject(0) { |sum, e| sum + e.total_hours }
    else
      @estimate = fetch_estimate_by_day_number day_number
      (@estimate ? @estimate.remaining_hours : 0.0)
    end
  end

  def remaining_qa_hours_for_day_number day_number
    if day_number == 0
      self.tasks.find_all { |t| t.qa && !t.pushed? }.map { |t| t.task_estimates }.flatten.find_all { |e| e.day_number == 1 }.inject(0) { |sum, e| sum + e.total_hours }
    else
      @estimate = fetch_estimate_by_day_number day_number
      (@estimate ? @estimate.remaining_qa_hours : 0.0)
    end
  end

  def total_hours_for_day_number day_number
    if day_number == 0
      self.remaining_hours_for_day_number(day_number)
    else
      @estimate = fetch_estimate_by_day_number day_number
      (@estimate ? @estimate.total_hours : 0.0)
    end
  end

  def velocity_for_day_number day_number
    @estimate = fetch_estimate_by_day_number day_number
    (@estimate ? @estimate.velocity : 0)
  end

  def points_delivered_for_day_number day_number
    @estimate = fetch_estimate_by_day_number day_number
    (@estimate ? @estimate.points_delivered : 0)
  end

  def total_hours
#    self.tasks.not_pushed.sum('total_hours')
    self.all_tasks.find_all { |t| t.status != STATUS_PUSHED }.inject(0.0) { |hours, t| hours + t.total_hours }
  end

  def remaining_hours
#    self.tasks.sum('remaining_hours')
    self.all_tasks.inject(0.0) { |hours, t| hours + t.remaining_hours }
  end

  def remaining_qa_hours
#    self.tasks.qa.sum('remaining_hours')
    self.all_tasks.find_all { |t| t.qa == true }.inject(0.0) { |hours, t| hours + t.remaining_hours }
  end

  def total_points
#    self.stories.pointed.sum('points')
    self.stories.find_all { |s| s.points && s.points > 0 }.inject(0) { |points, s| points + s.points }
  end

  def total_points_delivered
#    self.stories.accepted.sum('points')
    self.stories.find_all { |s| s.status == STATUS_ACCEPTED && s.points }.inject(0) { |points, s| points + s.points }
  end

  def calc_date day_num
    the_date = self.end_on
    (day_num..10).each do
      the_date = the_date - 1
      the_date = the_date - 2 if the_date.cwday == 7
      the_date = the_date -1 if the_date.cwday == 6
    end
    the_date
  end


  def calc_day_number duration_weeks=self.project.iteration_duration_weeks, the_date=self.project.calculate_project_date
#    puts the_date
    the_date = end_on if the_date > end_on
    day_num = 0

#    (self.end_on - (duration_weeks * 7)..the_date).each do |d|
    (self.start_on..the_date).each do |d|
      day_num += 1 if d.cwday < 6
    end
    day_num
  end

  @estimates = nil

  def fetch_estimate_by_day_number day_number
    self.task_estimates.find_all{|te| te.day_number == day_number}.first
#    fetch_estimate_by_date(self.calc_date(day_number))
  end

#  def fetch_estimate_by_date the_date
#    populate_estimates_hash unless @estimates
#    @estimates[the_date]
#  end

  def debug
    populate_estimates_hash unless @estimates
    @estimates.keys.each do |k|
      puts "#{k}: #{@estimates[k].try(:id)}"
    end
  end

  def stories_filtered(not_accepted_flag, pushed_flag)
    _stories = self.stories
    unless not_accepted_flag.nil? or not_accepted_flag == "Y"
      _stories = _stories.find_all { |s| s.status != STATUS_ACCEPTED }
    end
    unless pushed_flag.nil? or pushed_flag == "Y"
      _stories = _stories.find_all { |s| s.status != STATUS_PUSHED }
    end
    _stories
  end

  # collect all tasks without using the has_many :through capability (because we've already loaded all tasks in memory)
  def all_tasks
    self.stories.collect { |s| s.tasks }.flatten
  end

  private

#  def populate_estimates_hash
#    @estimates = {}
#    self.task_estimates.each do |e|
#      @estimates[e.as_of] = e
#    end
#  end
end
