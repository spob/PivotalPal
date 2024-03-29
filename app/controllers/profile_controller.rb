class ProfileController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  before_filter :fetch_user

  def edit
  end

  def update
    authorize! :update, @profile
    @profile.email = params[:user][:email]
    @profile.first_name = params[:user][:first_name]
    @profile.last_name = params[:user][:last_name]
    @profile.time_zone = params[:user][:time_zone]
    if @profile.save
      redirect_to(projects_path, :notice => t('profile.updated'))
    else
      render :action => "edit"
    end
  end

  private

  def fetch_user
    @profile = User.find(current_user)
  end
end
