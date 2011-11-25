require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  context "Given an existing project record" do
    setup do
      @project = FactoryGirl.create(:project)
    end
    subject { @project }

    should belong_to :tenant
    should validate_presence_of :name
    should validate_presence_of :tenant_id
    should validate_uniqueness_of(:name).scoped_to(:tenant_id)
  end
end
