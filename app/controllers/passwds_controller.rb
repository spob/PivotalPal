class PasswdsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :fetch_user

  def edit
  end

  def update
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
#    @user.reset_password_token = params[:user][:reset_password_token]
    @user.temporary_password = nil
    if @user.save
      redirect_to(root_path, :notice => t('password.updated'))
    else
      render :action => "edit"
    end
  end

  private

  def fetch_user
    @user = User.find(current_user)
  end
end
