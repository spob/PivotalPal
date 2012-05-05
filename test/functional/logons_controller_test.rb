require 'test_helper'

class LogonsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def self.should_deny_access
    should_respond_with :redirect
    should_assign_to :logons
    should_set_the_flash_to /not authorized/
    should_redirect_to("home page") { root_path }
    should "have empty logons" do
      assert_empty assigns(:logons)
    end
  end

  context "with logons defined" do
    setup do
      @logon1 = Factory.create(:logon)
      @logon2 = Factory.create(:logon)
    end

    context "on GET to :index" do
      setup { get :index }
      should_respond_with :redirect
      should_not_assign_to :logons
      should_set_the_flash_to /You need to sign in/
      should_redirect_to("sign in page") { new_user_session_path }
    end

    context "when logged in as a normal user" do
      setup do
        sign_in Factory.create(:user)
      end

      context "on GET to :index" do
        setup { get :index }
        should_deny_access
      end
    end

    context "when logged in as an admins user" do
      setup do
        sign_in Factory.create(:admins)
      end

      context "on GET to :index" do
        setup { get :index }
        should_deny_access
      end
    end

    context "when logged in as a super user" do
      setup do
        sign_in Factory.create(:superuser)
      end

      context "on GET to :index" do
        setup { get :index }
        should_respond_with :success
        should_assign_to :logons
        should_not_set_the_flash
        should "have logons populated" do
          assert_equal 2, assigns(:logons).size
        end
      end
    end
  end
end
