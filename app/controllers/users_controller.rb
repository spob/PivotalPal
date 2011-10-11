class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  load_and_authorize_resource
  respond_to :html, :xml

  # GET /users
  # GET /users.xml
  def index
    cookies[:users_search_show_users] = {:value => "ALL", :expires => 6.months.since} unless cookies[:users_search_show_users]
    cookies[:users_search_show_users] = {:value => params["show_users"], :expires => 6.months.since} if params["show_users"]
    users = User.where(:tenant_id => current_user.tenant.id).order("email")
    users = users.confirmed if cookies[:users_search_show_users] == "CONFIRMED"
    users = users.unconfirmed if cookies[:users_search_show_users] == "UNCONFIRMED"
    @users = users.page(params[:page]).per(DEFAULT_ROWS_PER_PAGE)
    respond_with @users
  end

  # GET /users/1
  # GET /users/1.xml
  #  def show
  #    respond_with @users
  #  end

  def edit
  end

  def update
    respond_to do |format|
      @user.email = params[:user][:email]
      @user.first_name = params[:user][:first_name]
      @user.last_name = params[:user][:last_name]
      @user.roles = params[:user][:roles]
      if @user.save
        format.html { redirect_to(users_path,
                                  :notice => t('general.updated',
                                               :entity => t('user.entity_name'),
                                               :identifier => @user.email)) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
end
