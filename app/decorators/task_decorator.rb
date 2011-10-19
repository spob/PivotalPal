class TaskDecorator < ApplicationDecorator
  decorates :task

  def display_description
    h.strike_text(model.description, model.status == "pushed")
  end

  def display_status
    h.content_tag(:td, style: "background-color: #{cell_color_by_task_status}") do
      h.content_tag(:span,  model.status.try(:titleize), style: "white-space: nowrap;")
    end
  end

  def display_estimate(d, story)
      @estimate = model.task_estimates.find_all{|e| e.day_number == d}.first
      h.content_tag(:td, task_estimate_for_day(@estimate), style: "background-color: #{cell_color_by_hours(@estimate, model, story)}")
  end

protected

  def cell_color_by_task_status
    case model.status
      when "Done" then
        "#B2EDAF"
      when "In Progress" then
        "#F5F4AB"
      when "Blocked" then
        "#FF7373"
      else
        " "
    end
  end

  def task_estimate_for_day estimate
    #puts "#{estimate ? "not null" : "nil"}::#{estimate} #{estimate.try(:status)}"
    (estimate && estimate.status != "pushed" ? '%.2f' % estimate.remaining_hours : "-")
  end


  def cell_color_by_hours estimate, task=estimate.task, story=estimate.task.story
    if estimate && ((estimate.total_hours > 0.0 && estimate.remaining_hours != estimate.total_hours) ||
        story.status == "accepted" || estimate.status == "Blocked") && task.status != "pushed"
      if estimate.remaining_hours == 0.0 && task.status != "pushed"
        "#B2EDAF"
      elsif estimate.status == "Blocked"
        "#FF7373"
      elsif estimate.remaining_hours < estimate.total_hours
        "#F5F4AB"
      end
    else
      ""
    end
  end
end
