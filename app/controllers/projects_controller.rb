class ProjectsController < ApplicationController
  load_and_authorize_resource
  before_filter :authenticate_user!
  before_filter :login_checks
  respond_to :html, :xml

  # GET /projects
  # GET /projects.xml
  def index
    @projects = @projects.includes(:latest_iteration).where(:tenant_id => current_user.tenant).order("name").page(params[:page]).per(DEFAULT_ROWS_PER_PAGE)

    respond_with @projects
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    unless @project.latest_iteration
      redirect_to(projects_path)
      return
    end
    cookies[:show_pushed_stories] = {:value => params[:show_pushed_stories], :expires => 6.month.since} if params[:show_pushed_stories]
    cookies[:show_accepted_stories] = {:value => params[:show_accepted_stories], :expires => 6.month.since} if params[:show_accepted_stories]

    @iteration = IterationDecorator.decorate(select_iteration(@project, params))
    respond_with @project
  end

# GET /projects/new
# GET /projects/new.xml
  def new
    @project = Project.new(:name => "{#{t('project.pending_refresh')}}",
                           :feature_prefix => "S", :bug_prefix => "D", :chore_prefix => "C", :release_prefix => "R",
                           :renumber_features => true, :renumber_chores => true,
                           :time_zone => current_user.time_zone)
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

  def refresh
    authorize! :refresh, @project
    respond_to do |format|
      if @project.update_attribute(:next_sync_at, Time.now)
        format.html do
          notice = t('project.refresh_scheduled', :project => @project.name)
          if @project.latest_iteration
            redirect_to(project_path(@project), :notice => notice)
          else
            redirect_to(projects_path, :notice => notice)
          end
        end
        format.xml { head :ok }
      else
        format.html do
          if @project.latest_iteration
            render :action => "show"
          else
            redirect_to(projects_path, "Internal error: update project failed")
          end
        end
        format.xml { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  def renumber
    authorize! :refresh, @project
    respond_to do |format|
      if @project.renumber
        format.html { redirect_to(project_path(@project),
                                  :notice => t('project.renumbered')) }
        format.xml { head :ok }
      else
        format.html { redirect_to(project_path(@project), :alert => t('project.renumber_failed')) }
        format.xml { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  def storyboard
    @iteration = IterationDecorator.decorate(select_iteration(@project, :iteration_id => @project.latest_iteration))
    respond_with @project
  end

  def print
    if params[:story_ids].nil?
      redirect_to(select_to_print_project_path(@project), :notice => t('story.must_select_to_print'))
    else
      @stories = Card.where(:id => params[:story_ids]).order(:iteration_number).order(:sort)
      authorize! :read, @stories
    end
  end

  def select_to_print
    authorize! :read, @project
    cookies[:story_state] = {:value => params[:story_state], :expires => 6.month.since} if params[:story_state]
    cookies[:story_state] = {:value => "current", :expires => 6.month.since} unless cookies[:story_state]
    @card_request = @project.fetch_story_cards(cookies[:story_state], current_user)
    respond_with @project
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

  protected

  def select_iteration project, v_params
    Iteration.includes(:task_estimates, {:tasks => :task_estimates}, :stories => {:tasks => :task_estimates}).find(v_params[:iteration_id] ? v_params[:iteration_id] : project.latest_iteration.id)
  end
end
