
module ManageIQ::Providers
  module CloudAutomationManager
    class ConfigurationManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
      def parse_legacy_inventory(manager)
        manager.with_provider_connection do |connection|
          # get templates
          template_url_str = ":30000/cam/api/v1/templates"
          type = "template"
          data = collect_configuration_inventory(connection, manager.url, template_url_str, type)
          ConfigurationManager::RefreshParser.configuration_inv_to_hashes(data)
          # get configured systems
          stack_url_str = ":30000/cam/api/v1/stacks"
          type = "stacks"
          data_systems = collect_configuration_inventory(connection, manager.url, stack_url_str, type)
          ConfigurationManager::RefreshParser.configuration_inv_to_hashes(data_systems)
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

      def collect_configuration_inventory(connection, base_url, api_url, type)
        result = {}
        # get tenant based on creds
        uri_str = base_url + ":30000/cam/tenant/api/v1/tenants/getTenantOnPrem"
        response = redirect_cam_api(uri_str,5,connection)
        body = response.body
        # Get the ID
        tenant_id = JSON.parse(body)["id"]
        # For demo use default
        team = "default"
        # Get all templates
        all = "all"
        # url to get all template resources
        template_uri_str = base_url + api_url + "?tenantId=" + tenant_id + "&ace_orgGuid=" + all + "&cloudOE_spaceGuid=" + team
        template_body = redirect_cam_api(template_uri_str, 5, connection)
        if type == "templates"
          result[:templates] = JSON.parse(template_body.body)
        else
          result[:stacks] = JSON.parse(template_body.body)
        end

        result
      end
    end
  end
end
