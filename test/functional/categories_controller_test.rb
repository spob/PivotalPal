require 'test_helper'

class CategoriesControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def self.should_require_login
    should respond_with :redirect
    should_not_assign_to :categories
    should_set_the_flash_to /You need to sign in/
    should_redirect_to("sign in page") { new_user_session_path }
  end

  context "with a category defined" do
    setup do
      @category = Factory.create(:category)
      assert_not_nil @category.id
    end

    context "and not logged in" do
      context "on GET to :index" do
        setup { get :index }
        should_require_login
      end

      context "on GET to :new" do
        setup { get :new }
        should_require_login
      end

      context "on GET to :edit" do
        setup { get :edit, :id => @category.to_param }
        should_require_login
      end

      context "on GET to :show" do
        setup { get :show, :id => @category.to_param }
        should_require_login
      end

      context "on POST to :create" do
        setup { post :create, :category => Factory.attributes_for(:category) }
        should_require_login
      end

      context "on PUT to :update" do
        setup { put :update, :id => @category, :category => @category.attributes }
        should_require_login
      end

      context "on DELETE to :destroy" do
        setup { delete :destroy, :id => @category }
        should_require_login
      end
    end

    context "when logged in as a normal user" do
      setup do
        sign_in Factory.create(:user)
      end

      context "on GET to :index" do
        setup { get :index }
        should_respond_with :success
        should_assign_to :categories
        should_not_set_the_flash
        should "have categories populated" do
          assert_equal 1, assigns(:categories).size
        end
      end

      context "on GET to :new" do
        setup { get :new }
        should_respond_with :success
        should_assign_to :category
        should_not_set_the_flash
      end

      context "on GET to :edit" do
        setup { get :edit, :id => @category }
        should_respond_with :success
        should_assign_to :category
        should_not_set_the_flash
      end

      context "on GET to :show" do
        setup { get :show, :id => @category.to_param }
        should_respond_with :success
        should_assign_to :category
        should_not_set_the_flash
      end

      context "on POST to :new" do
        setup do
          assert_difference('Category.count', 1) do
            post :create, :category => Factory.attributes_for(:category)
          end
        end

        should_redirect_to("index categories page") { categories_path }
        should_assign_to :category
        should_set_the_flash_to /successfully created/
      end

      context "on PUT to :update" do
        setup { put :update, :id => @category, :category => @category.attributes }

        should_redirect_to("show category page") { category_path }
        should_assign_to :category
        should_set_the_flash_to /successfully updated/
      end

      context "on DELETE to :destroy" do
        setup do
          assert_difference('Category.count', -1) do
            delete :destroy, :id => @category
          end
        end

        should_redirect_to("index category page") { categories_path }
        should_assign_to :category
        should_set_the_flash_to /successfully deleted/
      end
    end
  end
end
