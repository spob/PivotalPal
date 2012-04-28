class Story < ActiveRecord::Base
  belongs_to :iteration, :counter_cache => true
  has_many :tasks, :dependent => :destroy

  before_validation :adjust_points

  validates_presence_of :pivotal_identifier
  validates_presence_of :story_type
  validates_presence_of :url
  validates_presence_of :status
  validates_presence_of :name
  # No reason to enforce uniqueness...the database index will handle it for us
  #  validates_uniqueness_of :pivotal_identifier, :scope => :iteration_id
  validates_numericality_of :points, :only_integer => true, :allow_nil => true, :greater_than_or_equal_to => 0
  validates_numericality_of :sort, :only_integer => true, :allow_nil => true
  validates_length_of :story_type, :maximum => 10, :allow_blank => true
  validates_length_of :url, :maximum => 50, :allow_blank => true
  validates_length_of :status, :maximum => 20, :allow_blank => true
  validates_length_of :name, :maximum => 200, :allow_blank => true
  validates_length_of :owner, :maximum => 50, :allow_blank => true

  scope :accepted, where(:status => Constants::STATUS_ACCEPTED)
  scope :pushed, where(:status => Constants::STATUS_PUSHED)
  scope :pointed, where({:points => 0})
  scope :conditional_pushed, lambda { |param| return where("") if param.nil? or param == "Y"
  where { {status.not_eq => Constants::STATUS_PUSHED} }
  }
  scope :conditional_not_accepted, lambda { |param| return where("") if param.nil? or param == "Y"
  where { {status.not_eq => Constants::STATUS_ACCEPTED} }
  }

  def tasks_conditional_pushed(flag)
    return self.tasks if flag.nil? or flag == "Y"
    self.tasks.find_all { |t| t.status != Constants::STATUS_PUSHED }
  end

  def tasks_by_status v_status
    self.tasks.find_all { |t| t.status == v_status }
  end

  def push_tasks
    self.tasks.find_all { |t| t.status == "In Progress" || t.status == "Not Started" }.each do |t|
      body = ""
      resource_uri = URI.parse("http://www.pivotaltracker.com/services/v3/projects/#{self.iteration.project.pivotal_identifier}/stories/#{self.id}/tasks")
      http = Net::HTTP.new(resource_uri.host, resource_uri.port)
      req = Net::HTTP::Put.new(resource_uri.path, {'Content-type' => 'application/xml', 'X-TrackerToken' => self.iteration.project.tenant.api_key})
      http.use_ssl = false
    end
  end

  def update_pivotal
    Story.update_pivotal self.iteration.project,
                         self.pivotal_identifier,
                         :name => name, :description => body, :estimate => points, :story_type => story_type,
                         :current_state => status
#                         name :name, description :body, estimate :points, story_type :story_type, current_state :status
  end

  def self.build_body(params)
    buf = ""
    params.each { |key, val| buf = buf + "<#{key.to_s}><![CDATA[#{val}]]></#{key.to_s}>" }
    body = "<story>#{buf}</story>"
    body
  end

  def self.update_pivotal project, pivotal_identifier, params
    body = build_body(params)
    uri = "http://www.pivotaltracker.com/services/v3/projects/#{project.pivotal_identifier}/stories/#{pivotal_identifier}"
    call_pivotal_rest project, body, uri, :update
  end

  def split current_user
    begin
      task_pushed = false
      tasks.find_all { |t| t.status != Constants::STATUS_PUSHED && t.remaining_hours != t.total_hours }.each do |t|
        #puts ">>>>#{t.description}  status #{t.status} complete? #{t.pivotal_complete?}"
        Task.create_in_pivotal self, "#{t.status == "Blocked" ? "B" : "" }#{t.remaining_hours}/#{t.remaining_hours} #{t.strip_description}" unless t.pivotal_complete?
        t.status = Constants::STATUS_PUSHED
        t.description = "X#{t.description}"
        t.update_pivotal
        task_pushed = true
      end
      self.add_pivotal_comment I18n.t('story.split_comment', :user => current_user.full_name) if task_pushed
      "OK"
    rescue Exceptions::PivotalActionFailed => e
      e.message
    end
  end

  def copy_in_pivotal p_name=self.name
    new_story = Story.new
    new_story.story_type = self.story_type
    new_story.name = p_name
    new_story.body = self.body
    new_story.points = self.points
    new_story.iteration = self.iteration
    new_story.create_in_pivotal current_state :current_status
    new_story
  end

  def create_in_pivotal params={}
#    params = params.merge(name :name, description :body, estimate :points, story_type :story_type)
    params = params.merge(:name => name, :description => body, :estimate => points, :story_type => story_type)
    self.pivotal_identifier = Story.create_in_pivotal self.iteration.project, params
    self
  end

  def self.create_in_pivotal project, params
    body = build_body(params)
    uri = "http://www.pivotaltracker.com/services/v3/projects/#{project.pivotal_identifier}/stories"
    response = project.call_pivotal_rest body, uri, :create
    puts "response: #{response.body}"
    if response.code == "200"
      GC.start
      GC.disable
      begin
        doc = Hpricot(response.body)
        return doc.at('id').try(:inner_html)
      ensure
        GC.enable
      end
    end
  end

  def add_pivotal_comment comment
    body = "<note><text><![CDATA[#{comment}]]></text></note>"
    uri = "http://www.pivotaltracker.com/services/v3/projects/#{self.iteration.project.pivotal_identifier}/stories/#{self.pivotal_identifier}/notes"
    response = self.iteration.project.call_pivotal_rest body, uri, :create
    puts "response: #{response.body}"
  end

  def parse_story_number
    match = Regexp.new("^\\s*#{story_prefix_regex}\\d+").match(name)
    if match
      match[0]
    else
      nil
    end
  end

  def parse_story_name
    _name = self.name
    story_number = parse_story_number
    if story_number
      match = self.name.match /^\s*#{story_number}[\s]*(.*)/i
      if match
        _name = match.captures.last
      end
    end
    _name.strip
  end

  protected

  def story_prefix_regex
    regular_expression = "[#{self.iteration.project.bug_prefix}#{self.iteration.project.feature_prefix}#{self.iteration.project.release_prefix}#{self.iteration.project.chore_prefix}]"
    regular_expression == "[]" ? "" : regular_expression
  end

  def adjust_points
    self.points = nil if self.points == -1
  end

  def current_status
    case self.status
      when Constants::STATUS_STARTED
      then
        Constants::STATUS_STARTED
      else
        Constants::STATUS_NOT_STARTED
    end
  end
end
