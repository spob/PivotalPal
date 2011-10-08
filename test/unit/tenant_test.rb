require 'test_helper'

class TenantTest < ActiveSupport::TestCase
  context "Given an existing tenant record" do
    setup do
      @tenant = Factory.create(:tenant)
    end
    subject { @tenant }

    should validate_presence_of :name
    should validate_uniqueness_of :name
    should have_many :users
    should have_many :projects
    should have_many :pools
  end
end
