require 'test_helper'

class PoolTest < ActiveSupport::TestCase
  context "Given an existing pool record which increases on an anniversary" do
    setup do
      @pool = Factory.create(:pool, :increase_day_number => nil)
    end
    subject { @pool }

    should belong_to :tenant
    should validate_presence_of :name
    should validate_presence_of :tenant_id
    should validate_uniqueness_of(:name).scoped_to(:tenant_id)
    should ensure_length_of(:name).is_at_most(20)
#    should validate_presence_of :unlimited
    should validate_numericality_of :increase_rate
    should allow_value(1).for(:increase_rate)
    should allow_value(0.25).for(:increase_rate)
    should allow_value(0).for(:increase_rate)
    should_not allow_value(-2).for(:increase_rate)

    should allow_value(INCREASE_TYPE_NONE).for(:increase_type)
    should allow_value(INCREASE_TYPE_ANNUAL_ANNIVERSARY).for(:increase_type)
    should allow_value(INCREASE_TYPE_ANNUAL_DAY_OF_YEAR).for(:increase_type)
    should_not allow_value('xxx').for(:increase_type)

    should validate_numericality_of :increase_day_number
    should allow_value(1).for(:increase_day_number)
    should allow_value(25).for(:increase_day_number)
    should allow_value(365).for(:increase_day_number)
    should_not allow_value(-1).for(:increase_day_number)
    should_not allow_value(0).for(:increase_day_number)
    should_not allow_value(366).for(:increase_day_number)
    should_not allow_value(1.5).for(:increase_day_number)


    should validate_numericality_of :maximum_accrual_rate
    should allow_value(0).for(:maximum_accrual_rate)
    should allow_value(1).for(:maximum_accrual_rate)
    should allow_value(25.2).for(:maximum_accrual_rate)
    should_not allow_value(-1).for(:maximum_accrual_rate)

    should validate_numericality_of :accrual_day_number
    should allow_value(1).for(:accrual_day_number)
    should allow_value(25).for(:accrual_day_number)
    should allow_value(31).for(:accrual_day_number)
    should_not allow_value(-1).for(:accrual_day_number)
    should_not allow_value(0).for(:accrual_day_number)
    should_not allow_value(32).for(:accrual_day_number)
    should_not allow_value(1.5).for(:accrual_day_number)

    should validate_presence_of :increase_type
    should validate_presence_of :accrual_day_number
    should validate_presence_of :increase_rate
    should validate_presence_of :maximum_accrual_rate

    context "given a pool that increases on a day number" do
      setup do
        @pool.increase_type = INCREASE_TYPE_ANNUAL_DAY_OF_YEAR
        @pool.increase_day_number = 3
        @pool.save!
      end
      should validate_presence_of :increase_day_number
      should validate_presence_of :increase_rate
      should validate_presence_of :maximum_accrual_rate
    end

    context "given a pool that does not increase" do
      setup do
        @pool.increase_type = INCREASE_TYPE_NONE
        @pool.increase_day_number = nil
        @pool.increase_rate = nil
        @pool.maximum_accrual_rate = nil
        @pool.save!
      end

      should "exist" do
        assert_not_nil @pool
      end

      context "and a user with a nil hired at" do
        setup do
          @user = Factory.create(:user, :hired_at => nil)
        end

        should "have nil increase" do
          assert_nil @pool.annual_pto_increase(@user)
        end
      end

      context "and a user" do
        setup do
          @user = Factory.create(:user, :hired_at => 800.days.ago.to_date)
        end

        should "have zero increase" do
          assert_equal 0, @pool.annual_pto_increase(@user)
        end
      end
    end
  end

  context "given an unlimited pool" do
    setup do
      @pool = Factory.create(:unlimited_pool)
    end

    should "exist" do
      assert_not_nil @pool
    end

    should "have no increase" do
      assert_nil @pool.annual_pto_increase(@user)
    end

    context "and a user with an anniversary date" do
      setup do
        @user = Factory.create(:user, :hired_at => 400.days.ago.to_date)
      end
    end
  end

  context "given a pool that increases on an anniversary" do
    setup do
      @pool = Factory.create(:pool)
      @pool.increase_type = INCREASE_TYPE_ANNUAL_ANNIVERSARY
      @pool.increase_day_number = nil
      @pool.increase_rate = 8
      @pool.maximum_accrual_rate = 20
      @pool.save!
    end

    context "and a user with a nil hired at" do
      setup do
        @user = Factory.create(:user, :hired_at => nil)
      end

      should "have nil increase" do
        assert_nil @pool.annual_pto_increase(@user)
      end
    end

    context "and a user hired 2 years ago" do
      setup { @user = Factory.create(:user, :hired_at => 800.days.ago.to_date) }
      should "have an increase" do
        assert_equal 16, @pool.annual_pto_increase(@user)
      end
    end

    context "and a user with a future hire date" do
      setup { @user = Factory.create(:user, :hired_at => 5.days.since.to_date) }
      should "have zero increase" do
        assert_equal 0, @pool.annual_pto_increase(@user)
      end
    end

    context "and a user hired less than a year ago" do
      setup { @user = Factory.create(:user, :hired_at => 364.days.ago.to_date) }
      should "have zero increase" do
        assert_equal 0, @pool.annual_pto_increase(@user)
      end
    end

    context "and a user hired a really long time ago" do
      setup { @user = Factory.create(:user, :hired_at => 40.years.ago.to_date) }
      should "have the maximum increase" do
        assert_equal 20, @pool.annual_pto_increase(@user)
      end
    end
  end

  context "given a pool that increases on a set date" do
    setup do
      @pool = Factory.create(:pool)
      @pool.increase_type = INCREASE_TYPE_ANNUAL_DAY_OF_YEAR
      @pool.increase_day_number = 32 # February 1st
      @pool.increase_rate = 8
      @pool.maximum_accrual_rate = 20
      @pool.save!
    end

    context "and a user with a nil hired at" do
      setup do
        @user = Factory.create(:user, :hired_at => nil)
      end

      should "have nil increase" do
        assert_nil @pool.annual_pto_increase(@user)
      end
    end

#    context "and a user hired 2 years ago and change" do
#      setup { @user = Factory.create(:user, :hired_at => 800.days.ago.to_date) }
#      should "have an increase" do
#        assert_equal 16, @pool.annual_pto_increase(@user)
#      end
#    end
#
#    context "and a user with a future hire date" do
#      setup { @user = Factory.create(:user, :hired_at => 5.days.since.to_date) }
#      should "have zero increase" do
#        assert_equal 0, @pool.annual_pto_increase(@user)
#      end
#    end
#
#    context "and a user hired less than a year ago" do
#      setup { @user = Factory.create(:user, :hired_at => 364.days.ago.to_date) }
#      should "have zero increase" do
#        assert_equal 0, @pool.annual_pto_increase(@user)
#      end
#    end
#
#    context "and a user hired a really long time ago" do
#      setup { @user = Factory.create(:user, :hired_at => 40.years.ago.to_date) }
#      should "have the maximum increase" do
#        assert_equal 20, @pool.annual_pto_increase(@user)
#      end
#    end
  end
#
#  def create_date(month, day, year)
#    Date.parse("#{year}-#{month}-#{day}")
#  end
end
