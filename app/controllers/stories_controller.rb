class StoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  load_and_authorize_resource
end
