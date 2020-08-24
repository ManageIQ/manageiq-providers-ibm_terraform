module ManageIQ::Providers
  module IbmTerraform
    class ConfigurationManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
      def parse_legacy_inventory(manager)
        manager.with_provider_connection do |connection|
          data = collect_configuration_inventory(connection, manager.url)
          ConfigurationManager::RefreshParser.configuration_inv_to_hashes(data)
        end
      end

      def save_inventory(manager, target, hashes)
        EmsRefresh.save_configuration_manager_inventory(manager, hashes, target)
      end

      private

      def redirect_cam_api(url, limit = 5, connection)
        raise ArgumentError, 'HTTP redirect too deep' if limit == 0

        req = Net::HTTP::Get.new(url, { 'Authorization' => connection, 'Accept' => "application/json", "Content-Type" => "application/json"})
        response = Net::HTTP.start(url.host, url.port, use_ssl: true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) { |http| http.request(req) }
        case response
        when Net::HTTPSuccess     then response
        when Net::HTTPRedirection then redirect_cam_api(response['location'], limit - 1, connection)
        else
          response.error!
        end
      end

      def collect_configuration_inventory(connection, base_url)
        result = {}

        # get tenant based on creds
        tenant_uri = URI.parse(base_url)
        tenant_uri.port = 30000
        tenant_uri.path = "/cam/tenant/api/v1/tenants/getTenantOnPrem"

        response = redirect_cam_api(tenant_uri, 5, connection)
        tenant_id = JSON.parse(response.body)["id"]

        team = "default"
        all = "all"

        template_uri = URI.parse(base_url)
        template_uri.port = 30000
        template_uri.path = "/cam/api/v1/templates"
        template_uri.query = URI.encode_www_form("tenantId" => tenant_id, "ace_orgGuid" => all, "cloudOE_spaceGuid" => team)

        response = redirect_cam_api(template_uri, 5, connection)
        result[:templates] = JSON.parse(response.body)

        stack_uri = URI.parse(base_url)
        stack_uri.port = 30000
        stack_uri.path = "/cam/api/v1/stacks"
        stack_uri.query = URI.encode_www_form("tenantId" => tenant_id, "ace_orgGuid" => all, "cloudOE_spaceGuid" => team)

        response = redirect_cam_api(stack_uri, 5, connection)
        result[:stacks] = JSON.parse(response.body)

        result
      end
    end
  end
end
