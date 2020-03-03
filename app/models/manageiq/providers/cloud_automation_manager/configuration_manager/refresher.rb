module ManageIQ::Providers
  module CloudAutomationManager
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

      def redirect_cam_api(uri_str, limit = 5, connection)
        raise ArgumentError, 'HTTP redirect too deep' if limit == 0
        url = URI.parse(uri_str)
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

        response = redirect_cam_api(tenant_uri.to_s, 5,connection)

        # Get the ID
        tenant_id = JSON.parse(response.body)["id"]

        # For demo use default
        team = "default"
        # Get all templates
        all = "all"
        # get all templates

        template_uri = URI.parse(base_url)
        template_uri.port = 30000
        template_uri.path = "/cam/api/v1/templates"
        template_uri.query = "tenantId=#{tenant_id}&ace_orgGuid=#{all}&cloudOE_spaceGuid=#{team}"
        # get stacks
        #template_uri_str = base_url + ":30000/cam/api/v1/stacks?tenantId=" + tenant_id + "&ace_orgGuid=" + all + "&cloudOE_spaceGuid=" + team
        template_body = redirect_cam_api(template_uri.to_s, 5, connection)
        result[:templates] = JSON.parse(template_body.body)

        result
      end
    end
  end
end
