require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def self.should_require_login
    should_respond_with :redirect
    should_not_assign_to :user
    should_set_the_flash_to /You need to sign in/
    should_redirect_to("sign in page") { new_user_session_path }
  end

  def self.should_deny_access
    should_respond_with :redirect
    should_set_the_flash_to /not authorized/
    should_redirect_to("home page") { root_path }
  end

  context "with a user defined" do
    setup do
      @user = Factory.create(:user)
    end

    context "and not logged in" do
      context "on GET to :index" do
        setup { get :index }
        should_require_login
      end

      context "on GET to :edit" do
        setup { get :edit, :id => @user.to_param }
        should_require_login
      end

      context "on PUT to :update" do
        setup { put :update, :id => @user, :user => @user.attributes }
        should_require_login
      end
    end

    context "when logged in as a normal user" do
      setup do
        sign_in Factory.create(:user)
      end

      context "on GET to :index" do
        setup { get :index }
        should_deny_access
        should_assign_to :users
        should "have empty users" do
          assert_empty assigns(:users)
        end
      end

      context "on GET to :edit" do
        setup { get :edit, :id => @user.to_param }
        should_deny_access
        should_assign_to :user
      end

      context "on PUT to :update" do
        setup { put :update, :id => @user, :user => @user.attributes }
        should_deny_access
        should_assign_to :user
      end
    end

    context "when logged in as a super user" do
      setup do
        sign_in Factory.create(:superuser)
      end

      context "on GET to :index" do
        setup { get :index }
        should_respond_with :success
        should_assign_to :users
        should_not_set_the_flash
        should "have users populated" do
          assert_equal 1, assigns(:users).size
        end
      end

      context "on GET to :edit" do
        setup { get :edit, :id => @user }
        should_respond_with :success
        should_assign_to :user
        should_not_set_the_flash
      end

      context "on PUT to :update" do
        setup do
          put :update, :id => @user, :user => @user.attributes.merge("roles" => [])
        end
        should_redirect_to("index users page") { users_path }
        should_assign_to :user
        should_set_the_flash_to /successfully updated/
      end
    end
  end
end
