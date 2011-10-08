class ProjectsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  before_filter :find_project, :only => [:show, :edit, :update, :destroy]
  respond_to :html, :xml

  # GET /projects
  # GET /projects.xml
  def index
    @projects = Project.where(:tenant_id => current_user.tenant).order("name").page(params[:page]).per(DEFAULT_ROWS_PER_PAGE)

    respond_with @projects
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    respond_with @project
  end

# GET /projects/new
# GET /projects/new.xml
  def new
    @project = Project.new

    respond_with @project
  end

# GET /projects/1/edit
  def edit
  end

# POST /projects
# POST /projects.xml
  def create
    @project = Project.new(params[:project])
    @project.tenant = current_user.tenant

    respond_to do |format|
      if @project.save
        format.html { redirect_to(projects_path, :notice => t('general.created', :entity => t('project.entity_name'))) }
        format.xml { render :xml => @project, :status => :created, :location => @project }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

# PUT /projects/1
# PUT /projects/1.xml
  def update
    respond_to do |format|
      if @project.update_attributes(params[:project])
        format.html { redirect_to(@project,
                                  :notice => t('general.updated',
                                               :entity => t('project.entity_name'),
                                               :identifier => @project.name)) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

# DELETE /projects/1
# DELETE /projects/1.xml
  def destroy
    name = @project.name
    @project.destroy

    respond_to do |format|
      format.html { redirect_to(projects_path,
                                :notice => t('general.deleted',
                                             :entity => t('project.entity_name'),
                                             :identifier => name)) }
      format.xml { head :ok }
    end
  end

  private

  def find_project
    @project = Project.find(params[:id])
  end
end
