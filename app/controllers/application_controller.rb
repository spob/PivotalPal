class ApplicationController < ActionController::Base
  include LoginChecker
  protect_from_forgery

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  rescue_from ForcePasswordException do |exception|
    redirect_to edit_password_path(current_user), :alert => exception.message
  end
end
