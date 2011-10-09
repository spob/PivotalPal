require 'net/http'

class Project < ActiveRecord::Base
  belongs_to :tenant, :counter_cache => true
  has_many :iterations, :dependent => :destroy
  validates_presence_of :name
  validates_presence_of :tenant_id
  validates_presence_of :pivotal_identifier
  validates_uniqueness_of :pivotal_identifier, :scope => :tenant_id
  validates_numericality_of :pivotal_identifier, :only_integer => true, :allow_blank => true, :greater_than => 0
  validates_length_of :sync_status, :maximum => 200, :allow_blank => true



  def refresh
    GC.start
    GC.disable

    begin
      # fetch project
      logger.info("Refreshing project #{name}")
      resource_uri = URI.parse("http://www.pivotaltracker.com/services/v3/projects/#{self.pivotal_identifier}")
      response = Net::HTTP.start(resource_uri.host, resource_uri.port) do |http|
        http.get(resource_uri.path, {'X-TrackerToken' => self.tenant.api_key})
      end

      if response.code == "200"
        doc = Hpricot(response.body).at('project')

        self.name = doc.at('name').innerHTML
        self.iteration_duration_days = doc.at('iteration_length').innerHTML
#        unless self.new_record?
#          fetch_current_iteration || fetch_notes
#        end
        self.sync_status = I18n.t('general.ok')
      else
        self.sync_status =  I18n.t('project.id_not_found', :pivotal_identifier => self.pivotal_identifier)
      end
    ensure
      GC.enable
    end
  end
end
