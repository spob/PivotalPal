require 'test_helper'

class ProfileControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def self.should_require_login
    should_respond_with :redirect
    should_not_assign_to :profile
    should_set_the_flash_to /You need to sign in/
    should_redirect_to("sign in page") { new_user_session_path }
  end

  context "with a user defined" do
    setup do
      @profile = Factory.create(:user)
    end

    context "when logged in as a normal user" do
      setup do
        sign_in @profile
      end

      context "on GET to :edit" do
        setup { get :edit, :id => @profile }
        should_respond_with :success
        should_assign_to :profile
        should_not_set_the_flash
      end

      context "on PUT to :update" do
        setup do
          put :update, :id => @profile,
              :user => {:email => 'test@email.com', :first_name => 'first', :last_name => 'last'}
        end
        should_redirect_to("categories") { categories_path }
        should_assign_to :profile
        should_set_the_flash_to /successfully updated/
        should "update profile values" do
          assert_equal('test@email.com', assigns(:profile).email)
          assert_equal('first', assigns(:profile).first_name)
          assert_equal('last', assigns(:profile).last_name)
        end
      end
    end
  end
end
