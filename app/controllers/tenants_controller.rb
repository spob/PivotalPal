class TenantsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  before_filter :fetch_tenant
  load_and_authorize_resource

  def edit
  end

  def update
    @tenant.name = params[:tenant][:name]
    @tenant.api_key = params[:tenant][:api_key]
    if @tenant.save
      redirect_to(projects_path, :notice => t('tenant.updated'))
    else
      render :action => "edit"
    end
  end

  private

  def fetch_tenant
    @tenant = Tenant.find(current_user.tenant.id)
  end
end
