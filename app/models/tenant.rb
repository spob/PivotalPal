class Tenant < ActiveRecord::Base
  has_many :users
  has_many :categories
  has_many :pools
  validates_presence_of :name
  validates_uniqueness_of :name
  after_create :seed_new_tenant

  private

  def seed_new_tenant
    self.categories.create!(:name => 'Default')
  end
end
