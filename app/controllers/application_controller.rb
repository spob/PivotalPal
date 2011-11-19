class ApplicationController < ActionController::Base
  include LoginChecker
  include Exceptions
  protect_from_forgery
  before_filter :set_timezone

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  rescue_from ForcePasswordException do |exception|
    redirect_to edit_password_path(current_user), :alert => exception.message
  end

  # Set the timezone for a given user based upon their preference...if not logged on, use the system
  # default time time...this is called by the before_filter
  def set_timezone
    Time.zone = current_user.try(:time_zone) || 'Eastern Time (US & Canada)'
  end
end
