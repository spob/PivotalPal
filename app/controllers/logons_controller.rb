class LogonsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  load_and_authorize_resource
  respond_to :html, :xml

  def index
    @logons = @logons.order("created_at DESC").page(params[:page]).per(DEFAULT_ROWS_PER_PAGE)

    respond_with @logons
  end
end
