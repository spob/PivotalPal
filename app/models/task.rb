class Task < ActiveRecord::Base
  belongs_to :story, :counter_cache => true
  has_many :task_estimates, :dependent => :destroy

  validates_presence_of :pivotal_identifier
  validates_length_of :description, :maximum => 200, :allow_blank => true
  validates_length_of :status, :maximum => 20, :allow_blank => true

  scope :pushed, where(:status => "pushed")
  scope :not_pushed, where(:status.ne => "pushed")
  scope :qa, where(:qa => true)
  scope :conditional_pushed, lambda { |param| return where("") if param.nil? or param == "Y"
  where(:status.ne => "pushed")
  }

  @estimates = nil

  def fetch_estimate_by_day_number day_number, iteration=self.story.iteration
    fetch_estimate_by_date(iteration.calc_date(day_number))
  end

  def fetch_estimate_by_date the_date
    puts "fetch estimate for #{the_date}"
    populate_estimates_hash unless @estimates
    @estimates[the_date]
  end

  def self.sort_by_status tasks
    tasks.sort_by do |s|
      case s.status
        when "Done" then
          1
        when "Blocked" then
          2
        when "In Progress" then
          3
        when "Not Started" then
          4
        else
          7
      end
    end
  end

  private

  def populate_estimates_hash
    puts "populate hash"
    @estimates = {}
    self.task_estimates.each do |e|
      puts "populating has #{e.as_of}"
      @estimates[e.as_of] = e
    end
  end
end
