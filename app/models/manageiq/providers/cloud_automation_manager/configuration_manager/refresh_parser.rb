module ManageIQ::Providers
  module CloudAutomationManager
    class ConfigurationManager::RefreshParser
      include Vmdb::Logging

      def self.configuration_inv_to_hashes(inv)
        new.configuration_inv_to_hashes(inv)
      end

      def configuration_inv_to_hashes(inv)
        {
          :configuration_profiles => configuration_profile_inv_to_hashes(inv[:templates]),
          :configured_systems     => configured_system_inv_to_hashes(inv[:stacks])
        }
      end

      def configuration_profile_inv_to_hashes(profiles)
        type = "ManageIQ::Providers::CloudAutomationManager::ConfigurationManager::ConfigurationProfile".freeze

        profiles.to_a.collect do |profile|
          {
            :type        => type,
            :manager_ref => profile["id"].to_s,
            :name        => profile["name"],
            :description => profile["description"],
          }
        end
      end

      def configured_system_inv_to_hashes(configured_systems)
        configured_systems.to_a.collect do |cs|
          {
            :type         => "ManageIQ::Providers::CloudAutomationManager::ConfigurationManager::ConfiguredSystem",
            :manager_ref  => cs["id"].to_s,
            :hostname     => cs["name"],
            :last_checkin => cs["created_at"],
            :build_state  => cs["build"],
            :ipaddress    => cs["templateId"],
            :mac_address  => cs["status"],
            :ipmi_present => cs["templateName"]
          }
        end
      end
    end
  end
end
