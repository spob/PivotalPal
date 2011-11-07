class Story < ActiveRecord::Base
  belongs_to :iteration, :counter_cache => true
  has_many :tasks, :dependent => :destroy

  before_validation :adjust_points

  validates_presence_of :pivotal_identifier
  validates_presence_of :story_type
  validates_presence_of :url
  validates_presence_of :status
  validates_presence_of :name
  # No reason to enforce uniqueness...the database index will handle it for us
  #  validates_uniqueness_of :pivotal_identifier, :scope => :iteration_id
  validates_numericality_of :points, :only_integer => true, :allow_nil => true, :greater_than_or_equal_to => 0
  validates_numericality_of :sort, :only_integer => true, :allow_nil => true
  validates_length_of :story_type, :maximum => 10, :allow_blank => true
  validates_length_of :url, :maximum => 50, :allow_blank => true
  validates_length_of :status, :maximum => 20, :allow_blank => true
  validates_length_of :name, :maximum => 200, :allow_blank => true
  validates_length_of :owner, :maximum => 50, :allow_blank => true

  scope :accepted, where(:status => STATUS_ACCEPTED)
  scope :pushed, where(:status => STATUS_PUSHED)
  scope :pointed, where(:points.gte => 0)
  scope :conditional_pushed, lambda { |param| return where("") if param.nil? or param == "Y"
  where(:status.ne => STATUS_PUSHED)
  }
  scope :conditional_not_accepted, lambda { |param| return where("") if param.nil? or param == "Y"
  where(:status.ne => STATUS_ACCEPTED)
  }

  def tasks_conditional_pushed(flag)
    return self.tasks if flag.nil? or flag == "Y"
    self.tasks.find_all { |t| t.status != STATUS_PUSHED }
  end

  def tasks_by_status v_status
    self.tasks.find_all { |t| t.status == v_status }
  end

  protected

  def adjust_points
    self.points = nil if self.points == -1
  end
end
