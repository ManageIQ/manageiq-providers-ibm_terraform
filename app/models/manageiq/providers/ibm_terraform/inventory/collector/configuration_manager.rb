class ManageIQ::Providers::IbmTerraform::Inventory::Collector::ConfigurationManager < ManageIQ::Providers::IbmTerraform::Inventory::Collector
  def templates
    @templates ||= begin
      template_uri = URI.parse(manager.url)
      template_uri.port = 30000
      template_uri.path = "/cam/api/v1/templates"
      template_uri.query = URI.encode_www_form("tenantId" => tenant_id, "ace_orgGuid" => "all", "cloudOE_spaceGuid" => "default")
      response = redirect_cam_api(template_uri)
      JSON.parse(response.body)
    end
  end

  def stacks
    stack_uri = URI.parse(manager.url)
    stack_uri.port = 30000
    stack_uri.path = "/cam/api/v1/stacks"
    stack_uri.query = URI.encode_www_form("tenantId" => tenant_id, "ace_orgGuid" => "all", "cloudOE_spaceGuid" => "default")

    response = redirect_cam_api(stack_uri)
    JSON.parse(response.body)
  end

  private

  def tenant_id
    @tenant_id ||= begin
      tenant_uri = URI.parse(manager.url)
      tenant_uri.port = 30000
      tenant_uri.path = "/cam/tenant/api/v1/tenants/getTenantOnPrem"

      res = redirect_cam_api(tenant_uri)
      JSON.parse(res.body)["id"]
    end
  end

  def connection
    @connection ||= manager.connect
  end

  def redirect_cam_api(url, limit = 5)
    raise ArgumentError, 'HTTP redirect too deep' if limit == 0

    req = Net::HTTP::Get.new(url, {'Authorization' => connection, 'Accept' => "application/json", "Content-Type" => "application/json"})
    response = Net::HTTP.start(url.host, url.port, use_ssl: true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http| http.request(req) }
    case response
    when Net::HTTPSuccess     then response
    when Net::HTTPRedirection then redirect_cam_api(response['location'], limit - 1)
    else
      response.error!
    end
  end
end
