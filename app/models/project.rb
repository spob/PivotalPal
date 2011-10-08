class Project < ActiveRecord::Base
  belongs_to :tenant, :counter_cache => true
  validates_presence_of :name
  validates_presence_of :tenant_id
  validates_presence_of :project_identifier
  validates_uniqueness_of :name, :scope => :tenant_id
  validates_numericality_of :project_identifier, :only_integer => true, :allow_blank => true, :greater_than => 0
end
