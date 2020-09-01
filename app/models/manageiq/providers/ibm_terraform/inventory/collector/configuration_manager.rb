class ManageIQ::Providers::IbmTerraform::Inventory::Collector::ConfigurationManager < ManageIQ::Providers::IbmTerraform::Inventory::Collector
  def templates
    @templates ||= begin
      template_uri = URI.parse(manager.url)
      template_uri.path = "/cam/api/v1/templates"
      template_uri.query = URI.encode_www_form("tenantId" => tenant_id, "ace_orgGuid" => "all")
      response = redirect_cam_api(template_uri)
      JSON.parse(response.body)
    end
  end

  def virtual_machines
    @virtual_machines ||= begin
      iaas_resource_virtual_machine_uri = URI.parse(manager.url)
      iaas_resource_virtual_machine_uri.path = "/cam/api/v1/iaasresources"
      iaas_resource_virtual_machine_uri.query = URI.encode_www_form("filter" => '{"where": {"type": "virtual_machine"}}', "tenantId" => tenant_id, "ace_orgGuid" => "all")
      response = redirect_cam_api(iaas_resource_virtual_machine_uri)
      JSON.parse(response.body)
    end
  end

  private

  def tenant_id
    @tenant_id ||= begin
      tenant_uri = URI.parse(manager.url)
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

    verify_ssl = manager.default_endpoint.verify_ssl

    response = Net::HTTP.start(url.host, url.port, use_ssl: true, :verify_mode => verify_ssl) { |http| http.request(req) }
    case response
    when Net::HTTPSuccess     then response
    when Net::HTTPRedirection then redirect_cam_api(response['location'], limit - 1)
    else
      response.error!
    end
  end
end
