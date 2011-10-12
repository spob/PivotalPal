require 'net/http'

class Project < ActiveRecord::Base
  belongs_to :tenant, :counter_cache => true
  has_many :iterations, :dependent => :destroy
  has_one :latest_iteration, :class_name => "Iteration", :order => "iteration_number DESC"

  validates_presence_of :name
  validates_presence_of :tenant_id
  validates_presence_of :pivotal_identifier
  validates_uniqueness_of :pivotal_identifier, :scope => :tenant_id
  validates_numericality_of :pivotal_identifier, :only_integer => true, :allow_blank => true, :greater_than => 0
  validates_length_of :sync_status, :maximum => 200, :allow_blank => true

  scope :scheduled_to_sync, where(:next_sync_at.lt => Time.now).order(:next_sync_at)

  STATUS_PUSHED = "pushed"

  def self.sync_projects
    Project.scheduled_to_sync.select("id").find_each do |project|
      RunOncePeriodicJob.create_job("Sync Project", "Project.refresh(#{project.id})")
    end
  end

  def self.refresh id
    project = Project.find(id)
    project.refresh
    project.save
  end

  def refresh
    GC.start
    GC.disable

    begin
      # fetch project
      logger.info("Refreshing project #{name}")
      service_uri = "http://www.pivotaltracker.com/services/v3/projects/#{self.pivotal_identifier}"
      puts service_uri
      resource_uri = URI.parse(service_uri)
      response = Net::HTTP.start(resource_uri.host, resource_uri.port) do |http|
        http.get(resource_uri.path, {'X-TrackerToken' => self.tenant.api_key})
      end

      if response.code == "200"
        doc = Hpricot(response.body).at('project')

        self.name = doc.at('name').innerHTML
        self.iteration_duration_weeks = doc.at('iteration_length').innerHTML
        fetch_current_iteration unless self.new_record?
        self.sync_status = I18n.t('general.ok')
        self.last_synced_at = Time.now
      else
        self.sync_status = I18n.t('project.id_not_found', :pivotal_identifier => self.pivotal_identifier)
      end
      self.next_sync_at = self.tenant.refresh_frequency_hours.hours.since
    ensure
      GC.enable
    end
  end


  def fetch_current_iteration
    logger.info("fetch_current_iteration for project #{id}")
    resource_uri = URI.parse("http://www.pivotaltracker.com/services/v3/projects/#{pivotal_identifier}/iterations/current")
    response = Net::HTTP.start(resource_uri.host, resource_uri.port) do |http|
      http.get(resource_uri.path, {'X-TrackerToken' => self.tenant.api_key})
    end

    if response.code == "200"
      GC.start
      GC.disable

      begin
        doc = Hpricot(response.body)

        (doc/"iteration").each do |iteration|
          iteration_number = iteration.at('id').inner_html.to_i
#        start_on = iteration.at('start').inner_html.to_date
#        iteration_number = iteration_number - 1 if iteration_number > 1 && Project.calculate_project_date < start_on
          @iteration = self.iterations.where(:iteration_number => iteration_number).lock.first

#        puts "#{iteration.at('finish').inner_html} -- #{Date.parse(iteration.at('finish').inner_html)}"
          if @iteration
            start_on =
                @iteration.update_attributes!(:start_on => Date.parse(iteration.at('start').inner_html)+1,
                                              :end_on => Date.parse(iteration.at('finish').inner_html))
            @iteration.stories.each { |s| s.update_attributes!(:status => STATUS_PUSHED, :points => 0) }
          else
            @iteration = self.iterations.create!(:iteration_number => iteration_number,
                                                 :start_on => Date.parse(iteration.at('start').inner_html)+1,
                                                 :end_on => iteration.at('finish').inner_html)
          end
          n = 0
          (iteration.at('stories')/"story").each do |story|
            pivotal_id = story.at('id').inner_html.to_i
            @story = @iteration.stories.find_by_pivotal_identifier(pivotal_id)
            if @story
              @story.update_attributes!(:points => story.at('estimate').try(:inner_html),
                                        :status => story.at('current_state').inner_html,
                                        :name => story.at('name').inner_html,
                                        :owner => story.at('owned_by').try(:inner_html),
                                        :story_type => story.at('story_type').inner_html,
                                        :sort => n)

              @story.tasks.each do |t|
                t.update_attributes!(:status => STATUS_PUSHED, :remaining_hours => 0.0)
              end
            else
              @story = @iteration.stories.create!(:pivotal_identifier => story.at('id').inner_html,
                                                  :url => story.at('url').inner_html,
                                                  :points => story.at('estimate').try(:inner_html),
                                                  :status => story.at('current_state').inner_html,
                                                  :name => story.at('name').inner_html,
                                                  :owner => story.at('owned_by').try(:inner_html),
                                                  :story_type => story.at('story_type').inner_html,
                                                  :sort => n)
            end
            n = n + 1

            tasks = story.at('tasks')
            if tasks
              (tasks/"task").each do |task|
                pivotal_id = task.at('id').inner_html.to_i
                @task = @story.tasks.find_by_pivotal_identifier(pivotal_id)
                completed = (task.at('complete').inner_html == "true" || @story.status == "accepted" || @story.status == STATUS_PUSHED)
                total_hours, remaining_hours, description, is_qa = self.parse_hours(task.at('description').inner_html, completed)
#              puts "#{description}, QA: #{is_qa}" if is_qa
                status = calc_status(completed, remaining_hours, total_hours, description)

                if @task
                  @task.update_attributes!(:description => description,
                                           :total_hours => total_hours,
                                           :remaining_hours => remaining_hours,
                                           :status => status,
                                           :qa => is_qa)
                else
                  @task = @story.tasks.create!(:pivotal_identifier => task.at('id').inner_html,
                                               :description => description,
                                               :total_hours => total_hours,
                                               :remaining_hours => remaining_hours,
                                               :status => status,
                                               :qa => is_qa)
                end
#                puts "#{@task.description} #{total_hours} #{remaining_hours}"
                update_task_estimate(@task, @iteration)
              end
            end

            @story.tasks.pushed.each do |t|
              update_task_estimate(t, @iteration)
            end

            @estimate = @iteration.task_estimates.find_by_as_of(self.calc_iteration_day)
            if @estimate
              @estimate.update_attributes!(:total_hours => self.latest_iteration.total_hours,
                                           :remaining_hours => self.latest_iteration.remaining_hours,
                                           :remaining_qa_hours => self.latest_iteration.remaining_qa_hours,
                                           :points_delivered => self.latest_iteration.total_points_delivered,
                                           :velocity => self.latest_iteration.total_points)
            else
              @day = @iteration.task_estimates.create!(:as_of => self.calc_iteration_day,
                                                       :day_number => self.latest_iteration.calc_day_number,
                                                       :total_hours => self.latest_iteration.try(:total_hours),
                                                       :remaining_hours => self.latest_iteration.try(:remaining_hours),
                                                       :remaining_qa_hours => self.latest_iteration.try(:remaining_qa_hours),
                                                       :points_delivered => self.latest_iteration.try(:total_points_delivered),
                                                       :velocity => self.latest_iteration.try(:total_points))
            end
          end
          @iteration.stories.pushed.each do |s|
            s.tasks.each do |t|
              t.update_attributes!(:status => STATUS_PUSHED, :remaining_hours => 0.0)
              update_task_estimate(t, @iteration)
            end
          end

          @iteration.update_attributes!(:last_synced_at => Time.now)
        end
      ensure
        GC.enable
      end
      nil
    else
      "#{pivotal_identifier} not found in pivotal tracker"
    end
  end

  def parse_hours description, completed
    remaining_hours = 0.0
    total_hours = 0.0

    unless /^X\d/ix =~ description
      # does description start with a B (as in blocked)
      desc = description
      if /^B\d/ix =~ description
        desc = description[1..500]
      end
      m1 = /[\d.]*/x.match(desc)
      # Did the match end with a slash?
      if /\// =~ m1.post_match
        remaining_hours = m1[0].to_f if !completed

        m2 = /[\d.]*/x.match(m1.post_match[1..255])
        total_hours = m2[0].to_f
      end
    end

#    puts "TOTAL: #{total_hours} REMAINING: #{remaining_hours} #{description}"
    is_qa = /\[qa\]/xi =~ description
    return total_hours, remaining_hours, description, is_qa.present?
  end

  def calc_status(complete, remaining_hours, total_hours, description)
    status = "Not Started"
    if description =~ /^x/ix
      status = STATUS_PUSHED
    elsif description =~ /^b/ix
      status = "Blocked"
    elsif complete || (total_hours > 0.0 && remaining_hours == 0.0)
      status = "Done"
    elsif total_hours > 0.0 && remaining_hours < total_hours
      status = "In Progress"
    end
    status
  end

  def update_task_estimate task, iteration
    estimate = task.task_estimates.find_by_as_of(self.calc_iteration_day)
    if estimate
      estimate.update_attributes!(:total_hours => task.total_hours,
                                  :remaining_hours => task.remaining_hours,
                                  :status => task.status)
    else
      task.task_estimates.create!(:as_of => self.calc_iteration_day,
                                  :day_number => iteration.try(:calc_day_number),
                                  :iteration => iteration,
                                  :total_hours => task.total_hours,
                                  :remaining_hours => task.remaining_hours,
                                  :status => task.status)
    end
  end

  def calc_iteration_day the_date=Project.calculate_project_date
    (the_date.cwday > 5 ? the_date - (the_date.cwday - 5) : the_date)
  end

  def self.calculate_project_date
    Date.current
#    minutes = Time.now.in_time_zone(APP_CONFIG['default_user_timezone']).hour * 60 +
#        Time.now.in_time_zone(APP_CONFIG['default_user_timezone']).min
#    if minutes < APP_CONFIG['sprint_standup_time'].to_i
#      the_date = Date.current - 1
#    else
#      the_date = Date.current
#    end
#    the_date
  end
end
