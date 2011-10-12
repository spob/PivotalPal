class ProjectsController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_filter :login_checks
  respond_to :html, :xml

  # GET /projects
  # GET /projects.xml
  def index
    @projects = @projects.where(:tenant_id => current_user.tenant).order("name").page(params[:page]).per(DEFAULT_ROWS_PER_PAGE)

    respond_with @projects
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    cookies[:show_pushed_stories] = {:value => params[:show_pushed_stories], :expires => 6.month.since} if params[:show_pushed_stories]
    cookies[:show_accepted_stories] = {:value => params[:show_accepted_stories], :expires => 6.month.since} if params[:show_accepted_stories]

    if params[:iteration_id]
      @iteration = Iteration.includes(:task_estimates, :stories => {:tasks => :task_estimates}).find(params[:iteration_id])
    else
      @iteration = Iteration.last_iteration(@project).first
    end
    respond_with @project
  end

# GET /projects/new
# GET /projects/new.xml
  def new
    @project = Project.new(:name => "{#{t('project.pending_refresh')}}")
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
    @project.next_sync_at = Time.now

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
end
