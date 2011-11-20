module Pivotal

  def call_pivotal_rest body, uri, action
    logger.info(uri)
    logger.info(body)
    resource_uri = URI.parse(uri)
    http = Net::HTTP.new(resource_uri.host, resource_uri.port)
    req = nil
    params = {'Content-type' => 'application/xml', 'X-TrackerToken' => self.tenant.api_key}
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
    unless response.code == "200"
      error = "RESPONSE: #{response.code} #{response.body} #{response.message}"
      logger.error error
      raise Exceptions::PivotalActionFailed, error
    end
    response
  end
end
