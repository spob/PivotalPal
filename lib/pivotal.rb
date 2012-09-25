module Pivotal

  def call_pivotal_rest body, uri, action
    logger.info("PIVOTAL REQUEST: #{uri}")
    logger.info("BODY: #{body}")
    logger.info("ACTION: #{action}")
    logger.info("API KEY: \"#{self.tenant.api_key.strip}\"")
    resource_uri = URI.parse(uri)
    http = Net::HTTP.new(resource_uri.host, resource_uri.port)
    req = nil
    params = {'Content-type' => 'application/xml', 'X-TrackerToken' => self.tenant.api_key.strip}
    case action
      when :update
        req = Net::HTTP::Put.new(resource_uri.path, params)
      when :show
        req = Net::HTTP::Get.new(resource_uri.path, params)
      else
        req = Net::HTTP::Post.new(resource_uri.path, params)
    end
    http.use_ssl = false
    req.body = body if body
    response = http.request(req)
    if response.code == "200"
      logger.debug "RESPONSE: #{response.code} #{response.body} #{response.message}"
    else
      error = "RESPONSE: #{response.code} #{response.body} #{response.message}"
      logger.error error
      raise Exceptions::PivotalActionFailed, error
    end
    response
  end
end
