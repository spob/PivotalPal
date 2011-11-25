require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context "Given an existing user record" do
    setup do
      @user = FactoryGirl.create(:user)
    end
    subject { @user }

    should validate_uniqueness_of :email
    should belong_to :tenant
    should have_many :logons
    should have_many :direct_reports

    should ensure_length_of(:first_name).is_at_most(25)
    should validate_presence_of :last_name
    should ensure_length_of(:last_name).is_at_most(25)
#    should ensure_length_of(:company_name).is_at_most(50)

    should "return null years tenure" do
      assert_nil @user.years_tenure
    end
  end

  context "Given an existing user with a hired_at value of 1 year" do
    @user = FactoryGirl.create(:user, :hired_at => 400.days.ago)

    should "calculate tenure years" do
      assert_equal(1, @user.years_tenure)
    end
  end

  context "Given an existing user with a hired_at value of less than a year" do
    @user = FactoryGirl.create(:user, :hired_at => 400.days.ago)

    should "calculate tenure years" do
      assert_equal(0, @user.years_tenure)
    end
  end
end
