class TaskEstimate < ActiveRecord::Base
  belongs_to :iteration, :counter_cache => true
  belongs_to :task, :counter_cache => true

  validates_presence_of :as_of
  validates_presence_of :total_hours
  validates_presence_of :remaining_hours
  validates_length_of :status, :maximum => 20, :allow_blank => true
end
