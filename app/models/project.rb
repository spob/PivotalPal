class Project < ActiveRecord::Base
  belongs_to :tenant, :counter_cache => true
  validates_presence_of :name
  validates_presence_of :tenant_id
  validates_uniqueness_of :name, :scope => :tenant_id
end
