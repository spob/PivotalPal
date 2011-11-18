require 'net/http'

class Project < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, :use => :slugged

  belongs_to :tenant, :counter_cache => true
  belongs_to :master_project, :class_name => "Project", :foreign_key => :master_project_id, :counter_cache => :linked_projects_count
  has_many :iterations, :dependent => :destroy
  has_many :linked_projects, :class_name => "Project", :foreign_key => :master_project_id
  has_one :latest_iteration, :class_name => "Iteration", :order => "iteration_number DESC"

  validates_presence_of :name
  validates_presence_of :tenant_id
  validates_presence_of :pivotal_identifier
  validates_uniqueness_of :pivotal_identifier, :scope => :tenant_id
  validates_numericality_of :pivotal_identifier, :only_integer => true, :allow_blank => true, :greater_than => 0
  validates_length_of :sync_status, :maximum => 200, :allow_blank => true
  validates_length_of :feature_prefix, :maximum => 5, :allow_blank => true
  validates_length_of :chore_prefix, :maximum => 5, :allow_blank => true
  validates_length_of :release_prefix, :maximum => 5, :allow_blank => true
  validates_length_of :bug_prefix, :maximum => 5, :allow_blank => true

  scope :scheduled_to_sync, where(:next_sync_at.lt => Time.now).order(:next_sync_at)

  def self.sync_projects
    Project.scheduled_to_sync.select("id").find_each do |project|
      RunOncePeriodicJob.create_job("Sync Project", "Project.refresh(#{project.id})", 1.minute.ago)
    end
  end

  def self.refresh id
    project = Project.find(id)
    project.refresh
    project.save
  end

  def refresh
    return I18n.t('project.api_key_not_set') if self.tenant.api_key.nil?
    GC.start
    GC.disable

    begin
      # fetch project
      logger.info("Refreshing project #{name}")
      service_uri = "http://www.pivotaltracker.com/services/v3/projects/#{self.pivotal_identifier}"
#      puts service_uri
      resource_uri = URI.parse(service_uri)
      response = Net::HTTP.start(resource_uri.host, resource_uri.port) do |http|
        http.get(resource_uri.path, {'X-TrackerToken' => self.tenant.api_key})
      end

      if response.code == "200"
        doc = Hpricot(response.body).at('project')

        # Only change project name if it needs to be changed...otherwise it changes the slug
        project_name = doc.at('name').innerHTML.strip
        self.name = project_name unless self.name == project_name

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
    save
    self.sync_status == "OK"
  end


  def save_dirty_records(iteration)
    iteration.last_synced_at = Time.now
    iteration.save!
    iteration.task_estimates.each { |te| te.save! if te.changed? }
    iteration.stories.each do |s|
      s.save! if s.changed?
      s.tasks.each do |t|
        t.save! if t.changed?
        t.task_estimates.each do |te|
          te.save! if te.changed?
        end
      end
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
          @iteration = self.iterations.where(:iteration_number => iteration_number).includes(:task_estimates, :stories => {:tasks => :task_estimates}).lock.first

#        puts "#{iteration.at('finish').inner_html} -- #{Date.parse(iteration.at('finish').inner_html)}"
          if @iteration
            @iteration.start_on = Date.parse(iteration.at('start').inner_html)
            @iteration.end_on = Date.parse(iteration.at('finish').inner_html)-1
            @iteration.stories.each do |s|
              s.status = STATUS_PUSHED
              s.points = 0
            end
          else
            @iteration = self.iterations.create!(:iteration_number => iteration_number,
                                                 :start_on => Date.parse(iteration.at('start').inner_html),
                                                 :end_on => Date.parse(iteration.at('finish').inner_html)-1)
          end
#          puts "iteration id #{@iteration.id}, project: #{self.id}"
          n = 0
          (iteration.at('stories')/"story").each do |story|
            pivotal_id = story.at('id').inner_html.to_i
            @story = @iteration.stories.find_all { |s| s.pivotal_identifier == pivotal_id }.first
            if @story
              @story.points = story.at('estimate').try(:inner_html)
              @story.status = story.at('current_state').inner_html
              @story.name = story.at('name').inner_html[0..199]
              @story.body = story.at('description').try(:inner_html)
              @story.owner = story.at('owned_by').try(:inner_html)
              @story.story_type = story.at('story_type').inner_html
              @story.sort = n

              @story.tasks.each do |t|
                t.status = STATUS_PUSHED
                t.remaining_hours = 0.0
              end
            else
#              puts "Points: #{story.at('estimate').try(:inner_html)}"
              @story = @iteration.stories.create!(:pivotal_identifier => story.at('id').inner_html,
                                                  :url => story.at('url').inner_html,
                                                  :points => story.at('estimate').try(:inner_html),
                                                  :status => story.at('current_state').inner_html,
                                                  :name => story.at('name').inner_html[0..199],
                                                  :body => story.at('description').try(:inner_html),
                                                  :owner => story.at('owned_by').try(:inner_html),
                                                  :story_type => story.at('story_type').inner_html,
                                                  :sort => n)
            end
            n = n + 1

            tasks = story.at('tasks')
            if tasks
              (tasks/"task").each do |task|
                pivotal_id = task.at('id').inner_html.to_i
                @task = @story.tasks.find_all { |t| t.pivotal_identifier == pivotal_id }.first
                completed = (task.at('complete').inner_html == "true" || @story.status == STATUS_ACCEPTED || @story.status == STATUS_PUSHED)
                total_hours, remaining_hours, description, is_qa = self.parse_hours(task.at('description').inner_html, completed)
#              puts "#{description}, QA: #{is_qa}" if is_qa
                status = calc_status(completed, remaining_hours, total_hours, description)

                if @task
#                  puts "#{description}, remaining hours #{remaining_hours}"
                  @task.description = description[0..199]
                  @task.total_hours = total_hours
                  @task.remaining_hours = remaining_hours
                  @task.status = status
                  @task.qa = is_qa
                else
                  @task = @story.tasks.create!(:pivotal_identifier => task.at('id').inner_html,
                                               :description => description[0..199],
                                               :total_hours => total_hours,
                                               :remaining_hours => remaining_hours,
                                               :status => status,
                                               :qa => is_qa)
                end
#                puts "#{@task.description} #{total_hours} #{remaining_hours}"
                update_task_estimate(@task, @iteration)
              end
            end

            @story.tasks.find_all { |t| t.status == STATUS_PUSHED }.each do |t|
              update_task_estimate(t, @iteration)
            end

            @estimate = @iteration.task_estimates.find_all { |te| te.as_of == self.calc_iteration_day }.first
            if @estimate
              @estimate.total_hours = @iteration.total_hours
              @estimate.remaining_hours = @iteration.remaining_hours
              @estimate.remaining_qa_hours = @iteration.remaining_qa_hours
              @estimate.points_delivered = @iteration.total_points_delivered
              @estimate.velocity = @iteration.total_points
            else
              @day = @iteration.task_estimates.create!(:as_of => self.calc_iteration_day,
                                                       :day_number => @iteration.calc_day_number(self.iteration_duration_weeks),
                                                       :total_hours => @iteration.try(:total_hours),
                                                       :remaining_hours => @iteration.try(:remaining_hours),
                                                       :remaining_qa_hours => @iteration.try(:remaining_qa_hours),
                                                       :points_delivered => @iteration.try(:total_points_delivered),
                                                       :velocity => @iteration.try(:total_points))
            end
          end
          @iteration.stories.find_all { |s| s.status == STATUS_PUSHED }.each do |s|
            s.tasks.each do |t|
              t.status = STATUS_PUSHED
              t.remaining_hours = 0.0
              update_task_estimate(t, @iteration)
            end
          end

          save_dirty_records(@iteration)
        end
      ensure
        GC.enable
      end
      nil
    else
      "#{pivotal_identifier} not found in pivotal tracker"
    end
  end

  def fetch_story_cards(state, user)
    logger.info("fetch_current_iteration for project #{id}")
    resource_uri = URI.parse("http://www.pivotaltracker.com/services/v3/projects/#{pivotal_identifier}/iterations/#{state}")
    response = Net::HTTP.start(resource_uri.host, resource_uri.port) do |http|
      http.get(resource_uri.path, {'X-TrackerToken' => self.tenant.api_key})
    end

    if response.code == "200"
      GC.start
      GC.disable

      begin
        doc = Hpricot(response.body)

        card_request = CardRequest.create!(:user => user)

        (doc/"iteration").each do |iteration|
          iteration_number = iteration.at('id').inner_html.to_i
          (iteration.at('stories')/"story").each_with_index do |story, i|
            pivotal_id = story.at('id').inner_html.to_i
            card_request.cards.create!(:pivotal_identifier => story.at('id').inner_html,
                                       :url => story.at('url').inner_html,
                                       :iteration_number => iteration_number,
                                       :points => story.at('estimate').try(:inner_html),
                                       :status => story.at('current_state').inner_html,
                                       :name => story.at('name').inner_html[0..199],
                                       :body => story.at('description').try(:inner_html),
                                       :owner => story.at('owned_by').try(:inner_html),
                                       :story_type => story.at('story_type').inner_html,
                                       :sort => i)
          end
        end
        card_request
      end
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
    estimate = task.task_estimates.find_all { |te| te.as_of == self.calc_iteration_day }.first
    if estimate
      estimate.total_hours = task.total_hours
      estimate.remaining_hours = task.remaining_hours
      estimate.status = task.status
    else
      task.task_estimates.create!(:as_of => self.calc_iteration_day,
                                  :day_number => (iteration ? iteration.calc_day_number(self.iteration_duration_weeks) : nil),
                                  :iteration => iteration,
                                  :total_hours => task.total_hours,
                                  :remaining_hours => task.remaining_hours,
                                  :status => task.status)
    end
  end

  def calc_iteration_day the_date=self.calculate_project_date
    (the_date.cwday > 5 ? the_date - (the_date.cwday - 5) : the_date)
  end

  def calculate_project_date
    Time.now.in_time_zone(self.time_zone).to_date
#    minutes = Time.now.in_time_zone(APP_CONFIG['default_user_timezone']).hour * 60 +
#        Time.now.in_time_zone(APP_CONFIG['default_user_timezone']).min
#    if minutes < APP_CONFIG['sprint_standup_time'].to_i
#      the_date = Date.current - 1
#    else
#      the_date = Date.current
#    end
#    the_date
  end


  def renumber
    logger.info("renumber for project #{id}")
    resource_uri = URI.parse("http://www.pivotaltracker.com/services/v3/projects/#{pivotal_identifier}/stories")
    response = Net::HTTP.start(resource_uri.host, resource_uri.port) do |http|
      http.get(resource_uri.path, {'X-TrackerToken' => self.tenant.api_key})
    end

    if response.code == "200"
      GC.start
      GC.disable

      begin
        walk_stories_to_renumber Hpricot(response.body), 'feature' if self.renumber_features
        walk_stories_to_renumber Hpricot(response.body), 'chore' if self.renumber_chores
        walk_stories_to_renumber Hpricot(response.body), 'release' if self.renumber_releases
        walk_stories_to_renumber Hpricot(response.body), 'bug' if self.renumber_bugs
      ensure
        GC.enable
      end
      self.refresh
      self.sync_status = I18n.t('project.renumbered')
      true
    else
      self.sync_status = I18n.t('project.renumber_failed')
      logger.warn("Response Code: #{response.message} #{response.code}")
      false
    end
  end

  def walk_stories_to_renumber doc, story_type
    numbered_stories = {}
    unnumbered_stories = {}
    (doc/"story").each do |story|
      id = story.at('id').try(:inner_html)
      name = story.at('name').try(:inner_html)
      stype = story.at('story_type').try(:inner_html)
      if stype == story_type
        if (name =~ /^#{story_prefix(story_type)}\d+/ix)
          num = /\d+/x.match(name).to_s.to_i
          numbered_stories[num] = name
        else
          # un-numbered story
          unnumbered_stories[id] = name
        end
      end
    end
    next_story = next_story_number numbered_stories
    unnumbered_stories.each do |e|
      Story.update_pivotal self, e[0], name:"#{story_prefix(story_type)}#{next_story}: #{e[1]}"
      next_story = next_story_number(numbered_stories, next_story + 1)
    end
  end

  def transact_pivotal body, uri, action
    logger.info(uri)
    logger.info(body)
    resource_uri = URI.parse(uri)
    http = Net::HTTP.new(resource_uri.host, resource_uri.port)
    req = nil
    params = {'Content-type' => 'application/xml', 'X-TrackerToken' => self.tenant.api_key}
    case action
      when :update
        req = Net::HTTP::Put.new(resource_uri.path, params)
      else
        req = Net::HTTP::Post.new(resource_uri.path, params)
    end
    http.use_ssl = false
    req.body = body if body
    response = http.request(req)
    logger.info "RESPONSE: #{response.code} #{response.body} #{response.message}" unless response.code == "200"
    response
  end

  protected

  def story_prefix story_type
    case story_type
      when 'feature' then
        self.feature_prefix
      when 'chore' then
        self.chore_prefix
      when 'release' then
        self.release_prefix
      when 'bug' then
        self.bug_prefix
      else
        'X'
    end
  end

  def next_story_number stories, start_at=1
    for x in start_at..3000 do
      return x unless stories.has_key? x
    end
    0
  end

end
