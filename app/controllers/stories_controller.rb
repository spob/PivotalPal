class StoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :login_checks
  load_and_authorize_resource

  def split
    result = @story.split current_user
    result = @story.iteration.project.refresh if result == "OK"
    if result == "OK"
      notice = t('story.split', :story => @story.name)
    else
      notice = t('story.split_failed', :story => @story.name, :error => result)
    end
      redirect_to(project_path(@story.iteration.project), :notice => notice)
  end
end
