class Task < ActiveRecord::Base
  belongs_to :story, :counter_cache => true
  has_many :task_estimates, :dependent => :destroy

  validates_presence_of :pivotal_identifier
  validates_length_of :description, :maximum => 200, :allow_blank => true
  validates_length_of :status, :maximum => 20, :allow_blank => true

  scope :pushed, where(:status => "pushed")
  scope :not_pushed, where(:status.ne => "pushed")
  scope :qa, where(:qa => true)
end
