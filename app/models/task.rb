class Task < ActiveRecord::Base
  belongs_to :story, :counter_cache => true
  has_many :task_estimates, :dependent => :destroy

  validates_presence_of :pivotal_identifier
  validates_length_of :description, :maximum => 200, :allow_blank => true
  validates_length_of :status, :maximum => 20, :allow_blank => true

  scope :pushed, where(:status => STATUS_PUSHED)
  scope :not_pushed, where(:status.ne => STATUS_PUSHED)
  scope :qa, where(:qa => true)
  scope :conditional_pushed, lambda { |param| return where("") if param.nil? or param == "Y"
  where(:status.ne => STATUS_PUSHED)
  }

  @estimates = nil

  def fetch_estimate_by_day_number day_number, iteration=self.story.iteration
    fetch_estimate_by_date(iteration.calc_date(day_number))
  end

  def fetch_estimate_by_date the_date
    puts "fetch estimate for #{the_date}"
    populate_estimates_hash unless @estimates
    @estimates[the_date]
  end

  def pushed?
    self.status == STATUS_PUSHED
  end

  def update_pivotal
    body = "<task><description>#{description}</description><complete>#{pivotal_complete?.to_s}</complete></task>"
    uri = "http://www.pivotaltracker.com/services/v3/projects/#{story.iteration.project.pivotal_identifier}/stories/#{story.pivotal_identifier}/tasks/#{pivotal_identifier}"
    response = story.iteration.project.transact_pivotal body, uri, :update
    puts "response: #{response.body}"
  end

  def self.create_in_pivotal story, description
    body = "<task><description>#{description}</description></task>"
    uri = "http://www.pivotaltracker.com/services/v3/projects/#{story.iteration.project.pivotal_identifier}/stories/#{story.pivotal_identifier}/tasks"
    response = story.iteration.project.transact_pivotal body, uri, :create
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

  def pivotal_complete?
    status == STATUS_PUSHED || status == "Done"
  end

  def strip_description
    match = self.description.match /^\s*X?[\d.]+\/[\d.]+[\s]*(.*)/i
    if match
      match.captures.last
    else
      description
    end
  end

  private

  def populate_estimates_hash
    puts "populate hash"
    @estimates = {}
    self.task_estimates.each do |e|
      puts "populating has #{e.as_of}"
      @estimates[e.as_of] = e
    end
  end
end
