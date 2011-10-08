require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  def self.should_require_login
    should respond_with :redirect
    should_not_assign_to :projects
    should_set_the_flash_to /You need to sign in/
    should_redirect_to("sign in page") { new_user_session_path }
  end

  context "with a project defined" do
    setup do
      @project = Factory.create(:project)
      assert_not_nil @project.id
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
        setup { get :edit, :id => @project.to_param }
        should_require_login
      end

      context "on GET to :show" do
        setup { get :show, :id => @project.to_param }
        should_require_login
      end

      context "on POST to :create" do
        setup { post :create, :project => Factory.attributes_for(:project) }
        should_require_login
      end

      context "on PUT to :update" do
        setup { put :update, :id => @project, :project => @project.attributes }
        should_require_login
      end

      context "on DELETE to :destroy" do
        setup { delete :destroy, :id => @project }
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
        should_assign_to :projects
        should_not_set_the_flash
        should "have projects populated" do
          assert_equal 1, assigns(:projects).size
        end
      end

      context "on GET to :new" do
        setup { get :new }
        should_respond_with :success
        should_assign_to :project
        should_not_set_the_flash
      end

      context "on GET to :edit" do
        setup { get :edit, :id => @project }
        should_respond_with :success
        should_assign_to :project
        should_not_set_the_flash
      end

      context "on GET to :show" do
        setup { get :show, :id => @project.to_param }
        should_respond_with :success
        should_assign_to :project
        should_not_set_the_flash
      end

      context "on POST to :new" do
        setup do
          assert_difference('Project.count', 1) do
            post :create, :project => Factory.attributes_for(:project)
          end
        end

        should_redirect_to("index projects page") { projects_path }
        should_assign_to :project
        should_set_the_flash_to /successfully created/
      end

      context "on PUT to :update" do
        setup { put :update, :id => @project, :project => @project.attributes }

        should_redirect_to("show project page") { project_path }
        should_assign_to :project
        should_set_the_flash_to /successfully updated/
      end

      context "on DELETE to :destroy" do
        setup do
          assert_difference('Project.count', -1) do
            delete :destroy, :id => @project
          end
        end

        should_redirect_to("index project page") { projects_path }
        should_assign_to :project
        should_set_the_flash_to /successfully deleted/
      end
    end
  end
end
