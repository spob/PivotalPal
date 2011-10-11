class SuperUsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  before_filter :fetch_user, :only => [:edit, :update]
  respond_to :html, :xml

  # GET /positions
  # GET /positions.xml
  def index
    cookies[:super_users_search_show_users] = {:value => "ALL", :expires => 6.months.since} unless cookies[:super_users_search_show_users]
    cookies[:super_users_search_show_users] = {:value => params[:show_users], :expires => 6.months.since} if params[:show_users]
    users = User.order("email")
    users = users.confirmed if cookies[:super_users_search_show_users] == "CONFIRMED"
    users = users.unconfirmed if cookies[:super_users_search_show_users] == "UNCONFIRMED"
    @users = users.page(params[:page]).per(DEFAULT_ROWS_PER_PAGE)
    @users.each { |u| authorize! :read, u }
    respond_with @users
  end

  # GET /positions/1
  # GET /positions/1.xml
  #  def show
  #    respond_with @users
  #  end

  def edit
  end

  def update
    respond_to do |format|
#      params[:user][:roles] ||= []
      @user.email = params[:user][:email]
      @user.first_name = params[:user][:first_name]
      @user.last_name = params[:user][:last_name]
      @user.roles = params[:user][:roles]
      if @user.save
        format.html { redirect_to(super_users_path,
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

  private

  def fetch_user
    @user = User.find(params[:id])
  end
end
