class IterationDecorator < ApplicationDecorator
  decorates :iteration
#  allows [:iteration_number, :start_on]

# Accessing Helpers
#   You can access any helper via a proxy
#
#   Normal Usage: helpers.number_to_currency(2)
#   Abbreviated : h.number_to_currency(2)
#
#   Or, optionally enable "lazy helpers" by calling this method:
#     lazy_helpers
#   Then use the helpers with no proxy:
#     number_to_currency(2)

# Defining an Interface
#   Control access to the wrapped subject's methods using one of the following:
#
#   To allow only the listed methods (whitelist):
#     allows :method1, :method2
#
#   To allow everything except the listed methods (blacklist):
#     denies :method1, :method2

# Presentation Methods
#   Define your own instance methods, even overriding accessors
#   generated by ActiveRecord:
#
#   def created_at
#     h.content_tag :span, time.strftime("%a %m/%d/%y"),
#                   :class => 'timestamp'
#   end

  def remaining_hours_by_day
    values_by_day(0, true) { |x| model.remaining_hours_for_day_number(x) }
  end

  def chart_remaining_hours_by_day
    chart_data_by_day(true) { |x| model.remaining_hours_for_day_number(x) }
  end

  def remaining_qa_hours_by_day
    values_by_day(0, true) { |x| model.remaining_qa_hours_for_day_number(x) }
  end

  def chart_remaining_qa_hours_by_day
    chart_data_by_day(true) { |x| model.remaining_qa_hours_for_day_number(x) }
  end

  def total_hours_by_day
    values_by_day(0, true) { |x| model.total_hours_for_day_number(x) }
  end

  def chart_total_hours_by_day
    chart_data_by_day(true) { |x| model.total_hours_for_day_number(x) }
  end

  def completed_hours_by_day
    values_by_day(1, true) do |x|
      completed_hours_for_day x
    end
  end

  def completed_hours
    completed_hours_for_day(model.calc_day_number)
  end

  def completed_hours_for_day(x)
    if model.total_hours_for_day_number(x) && model.remaining_hours_for_day_number(x)
      model.total_hours_for_day_number(x) - model.remaining_hours_for_day_number(x)
    else
      return_nil(x)
    end
  end

  def chart_ideal_hours_by_day
    chart_data_by_day(true) { |x| calculate_ideal_hours(x) }
  end

  def velocity_by_day
    values_by_day(1, false) { |x| model.velocity_for_day_number(x) }
  end

  def chart_velocity_by_day
    chart_data_by_day(true) { |x| model.velocity_for_day_number(x) }
  end

  def points_delivered_by_day
    values_by_day(1, false) { |x| model.points_delivered_for_day_number(x) }
  end

  def chart_points_delivered_by_day
    chart_data_by_day(true) { |x| model.points_delivered_for_day_number(x) }
  end

  def decorated_stories show_accepted, show_pushed, owner
    sort_by_status(model.stories_filtered(show_accepted, show_pushed, owner).map { |s| StoryDecorator.decorate(s) })
  end

  def day_headings
    (1..model.calc_day_number).collect { |d| h.content_tag(:th, "#{d}") }.join.html_safe
  end

  def story_count_by_status status
    model.stories_by_status(status).size
  end

  def task_count_by_status status
    case status
      when Constants::STATUS_FINISHED then
        model.all_tasks.find_all { |t| t.remaining_hours == 0 && t.total_hours > 0 }.size
      when Constants::STATUS_STARTED then
        model.all_tasks.find_all { |t| t.remaining_hours < t.total_hours && t.total_hours > 0 }.size
      when Constants::STATUS_NOT_STARTED then
        model.all_tasks.find_all { |t| t.remaining_hours == t.total_hours && t.total_hours > 0 }.size
    end
  end

  protected

  def calculate_ideal_hours(d)
    max = chart_total_hours_by_day.max
    daily = max/(model.project.iteration_duration_weeks * 5.0)
    max - daily * d
  end

  def sort_by_status stories
    stories.sort_by do |s|
      case s.status
        when Constants::STATUS_ACCEPTED then
          1000 + (s.sort ? s.sort : 0)
        when Constants::STATUS_DELIVERED then
          2000 + (s.sort ? s.sort : 0)
        when Constants::STATUS_FINISHED then
          3000 + (s.sort ? s.sort : 0)
        when Constants::STATUS_REJECTED then
          4000 + (s.sort ? s.sort : 0)
        when Constants::STATUS_STARTED then
          5000 + (s.sort ? s.sort : 0)
        when Constants::STATUS_NOT_STARTED then
          6000 + (s.sort ? s.sort : 0)
        when Constants::STATUS_PUSHED then
          7000 + (s.sort ? s.sort : 0)
      end
    end
  end

  def values_by_day(start_day_number, format_as_hours=true, &block)
    buf = h.content_tag(:td, "-")
    buf = buf + h.content_tag(:td, "-") if start_day_number == 1
    (start_day_number..model.calc_day_number).each do |d|
      v = block.call(d)
      buf = buf + h.content_tag(:td, (format_as_hours ? format_hours(v) : v))
    end
    buf.html_safe
  end

  def chart_data_by_day(calc_day_zero, &block)
    (0..model.calc_day_number).each.collect { |x| x }.map do |d|
      if d == 0 and !calc_day_zero
        block.call(1)
      else
        block.call(d)
      end
    end
  end

  def format_hours hours
    if hours
      '%.2f' % hours
    else
      "0.0"
    end
  end

  def return_nil x
    nil
  end
end
