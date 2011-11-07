class Task < ActiveRecord::Base
  belongs_to :story, :counter_cache => true
  has_many :task_estimates, :dependent => :destroy

  validates_presence_of :pivotal_identifier
  validates_length_of :description, :maximum => 200, :allow_blank => true
  validates_length_of :status, :maximum => 20, :allow_blank => true

  scope :pushed, where(:status => STATUS_PUSHED)
  scope :not_pushed, where(:status.ne => STATUS_PUSHED)
  scope :qa, where(:qa => true)
  scope :conditional_pushed, lambda { |param| return where("") if param.nil? or param == "Y"
  where(:status.ne => STATUS_PUSHED)
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

  def pushed?
    self.status == STATUS_PUSHED
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
