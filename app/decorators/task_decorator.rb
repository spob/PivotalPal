class TaskDecorator < ApplicationDecorator
  decorates :task

  def display_description
    h.strike_text(model.description, model.status == Constants::STATUS_PUSHED)
  end

  def display_status
    h.content_tag(:td, style: "background-color: #{cell_color_by_task_status}") do
      h.content_tag(:span, model.status.try(:titleize), style: "white-space: nowrap;")
    end
  end

  def display_estimate(d, story)
    @estimate = model.task_estimates.find_all { |e| e.day_number == d }.first
    h.content_tag(:td, task_estimate_for_day(@estimate), style: "background-color: #{cell_color_by_hours(@estimate, model, story)}")
  end

  def post_it
    h.content_tag(:p, model.description, style: "border:2px solid #{post_it_border_color(model)};padding:5px 10px 15px 10px;margin:10px;background-color:##{ post_it_background_color(model) }")
  end

  protected

  def post_it_background_color task
    task.qa ? 'ffccff' : 'ffff99'
  end

  def post_it_border_color task
    case task.status
      when "Done" then
        'green'
      when "Blocked" then
        'red'
      else
        'black'
    end
  end

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
    (estimate && estimate.status != Constants::STATUS_PUSHED ? '%.2f' % estimate.remaining_hours : "-")
  end


  def cell_color_by_hours estimate, task=estimate.task, story=estimate.task.story
    if estimate && ((estimate.total_hours > 0.0 && estimate.remaining_hours != estimate.total_hours) ||
        story.status == Constants::STATUS_ACCEPTED || estimate.status == "Blocked") && task.status != Constants::STATUS_PUSHED
      if estimate.remaining_hours == 0.0 && task.status != Constants::STATUS_PUSHED
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
