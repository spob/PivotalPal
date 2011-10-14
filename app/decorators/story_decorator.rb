class StoryDecorator < ApplicationDecorator
  decorates :story

  def story_icon
    h.image_tag("pivotal/#{model.story_type}.png", options = {:alt=>"active"})
  end

  def display_name
    h.content_tag(:span, "#{h.strike_text(h.link_to(model.name, model.url, :target => '_blank'), model.status == 'pushed')} (#{model.status.titleize}), #{h.pluralize(model.points, 'point')}, #{owner_text})".html_safe, style: "font-size:125%;")
  end

  def cell_color_by_story_status
    case model.status
      when "accepted" then
        "#B2EDAF"
      when "delivered" then
        "#66CCFF"
      when "finished" then
        "#FFCC33"
      when "rejected" then
        "#FF7373"
      when "started" then
        "#F5F4AB"
      else
        "grey"
    end
  end

  def owner_text
    if model.owner
      "#{h.t('story.owned_by')} #{model.owner}"
    else
      h.t('story.not_owned')
    end
  end

  def decorated_tasks show_pushed
    sort_by_status(model.tasks_conditional_pushed(show_pushed).map{|t| TaskDecorator.decorate(t)})
  end

  protected

  def sort_by_status tasks
    tasks.sort_by do |s|
      case s.status
        when "Done" then
          1
        when "Blocked" then
          2
        when "In Progress" then
          3
        when "Not Started" then
          4
        else
          7
      end
    end
  end
end
