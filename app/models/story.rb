class Story < ActiveRecord::Base
  belongs_to :iteration, :counter_cache => true
  has_many :tasks, :dependent => :destroy

  before_validation :adjust_points

  validates_presence_of :pivotal_identifier
  validates_presence_of :story_type
  validates_presence_of :url
  validates_presence_of :status
  validates_presence_of :name
  validates_uniqueness_of :pivotal_identifier, :scope => :iteration_id
  validates_numericality_of :points, :only_integer => true, :allow_nil => true, :greater_than_or_equal_to => 0
  validates_numericality_of :sort, :only_integer => true, :allow_nil => true
  validates_length_of :story_type, :maximum => 10, :allow_blank => true
  validates_length_of :url, :maximum => 50, :allow_blank => true
  validates_length_of :status, :maximum => 20, :allow_blank => true
  validates_length_of :name, :maximum => 200, :allow_blank => true
  validates_length_of :owner, :maximum => 50, :allow_blank => true

  scope :accepted, where(:status => "accepted")
  scope :pushed, where(:status => "pushed")
  scope :pointed, where(:points.gte => 0)
  scope :conditional_pushed, lambda { |param| return where("") if param.nil? or param == "Y"
  where(:status.ne => "pushed")
  }
  scope :conditional_not_accepted, lambda { |param| return where("") if param.nil? or param == "Y"
  where(:status.ne => "accepted")
  }

    def self.sort_by_status stories
    stories.sort_by do |s|
      case s.status
        when "accepted" then
          1000 + (s.sort ? s.sort : 0)
        when "delivered" then
          2000 + (s.sort ? s.sort : 0)
        when "finished" then
          3000 + (s.sort ? s.sort : 0)
        when "rejected" then
          4000 + (s.sort ? s.sort : 0)
        when "started" then
          5000 + (s.sort ? s.sort : 0)
        when "unstarted" then
          6000 + (s.sort ? s.sort : 0)
        when "pushed" then
          7000 + (s.sort ? s.sort : 0)
      end
    end
    end

  def tasks_conditional_pushed(flag)
    return self.tasks if flag.nil? or flag == "Y"
    self.tasks.find_all{|t| t.status != "pushed"}
  end

  protected

  def adjust_points
    self.points = nil if self.points == -1
  end
end
