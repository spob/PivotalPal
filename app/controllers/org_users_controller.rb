class OrgUsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  respond_to :html, :xml

  def index
    redirect_to users_path
  end

# GET /users/new
# GET /users/new.xml
  def new
    @user = User.new

    respond_with @user
  end

# POST /org_users
# POST /org_users.xml
  def create
    @user = User.new
    @user.email = params[:user][:email]
    @user.first_name = params[:user][:first_name]
    @user.last_name = params[:user][:last_name]
    @user.roles = params[:user][:roles]
    @user.hired_at = params[:user][:hired_at]
    password = User.random_pronouncable_password
    @user.password = password
    @user.temporary_password = password
    @user.tenant = current_user.tenant

    respond_to do |format|
      User.invite!(:email => @user.email,
                   :first_name => @user.first_name, :last_name => @user.last_name) do |u|
        u.tenant = @user.tenant
        u.roles = @user.roles
      end
      #if @user.save
      format.html { redirect_to(users_path, :notice => t('user.invited')) }
      format.xml { render :xml => @user, :status => :created, :location => @user }
    end
  end
end
