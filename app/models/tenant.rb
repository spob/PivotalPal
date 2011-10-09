class Tenant < ActiveRecord::Base
  has_many :users, :dependent => :destroy
  has_many :projects, :dependent => :destroy
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 50, :allow_blank => true
  validates_length_of :api_key, :maximum => 32, :allow_blank => true
  after_create :seed_new_tenant

  private

  def seed_new_tenant
#    self.projects.create!(:name => 'Default')
  end
end
