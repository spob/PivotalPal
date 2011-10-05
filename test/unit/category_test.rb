require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  context "Given an existing category record" do
    setup do
      @category = Factory.create(:category)
    end
    subject { @category }

    should belong_to :tenant
    should validate_presence_of :name
    should validate_presence_of :tenant_id
    should validate_uniqueness_of(:name).scoped_to(:tenant_id)
  end
end
