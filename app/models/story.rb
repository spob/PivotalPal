class Story < ActiveRecord::Base
  belongs_to :iteration, :counter_cache => true
  has_many :tasks, :dependent => :destroy

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
end
