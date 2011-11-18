class StoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  load_and_authorize_resource

  def split
    @story.split
    @story.iteration.project.refresh
    redirect_to(project_path(@story.iteration.project), :notice => t('story.split', :story => @story.name))
  end
end
