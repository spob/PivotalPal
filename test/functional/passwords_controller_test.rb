require 'test_helper'

class PasswordsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def self.should_require_login
    should_respond_with :redirect
    should_not_assign_to :profile
    should_set_the_flash_to /You need to sign in/
    should_redirect_to("sign in page") { new_user_session_path }
  end

  context "with a user defined" do
    setup do
      @user = Factory.create(:user)
    end

    context "when logged in as a normal user" do
      setup do
        sign_in @user
      end

      context "on GET to :edit" do
        setup { get :edit, :id => @user }
        should_respond_with :success
        should_assign_to :user
        should_not_set_the_flash
      end

      context "on PUT to :update" do
        setup do
          put :update, :id => @user,
              :user => {:password => 'somelongpassword', :password_confirmation => 'somelongpassword'}
        end
        should_redirect_to("root") { root_path }
        should_assign_to :user
        should_set_the_flash_to /successfully changed/
      end
    end
  end
end
