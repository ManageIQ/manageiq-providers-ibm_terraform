module ManageIQ::Providers
  module CloudAutomationManager
    class ConfigurationManager::RefreshParser
      include Vmdb::Logging

      def self.configuration_inv_to_hashes(inv)
        new.configuration_inv_to_hashes(inv)
      end

      def configuration_inv_to_hashes(inv)
        {
          :configuration_profiles => configuration_profile_inv_to_hashes(inv[:hostgroups]),
          :configured_systems     => configured_system_inv_to_hashes(inv[:hosts])
        }
      end

      def configuration_profile_inv_to_hashes(profiles)
        profiles.to_a.collect do |profile|
          {
            :type        => "ManageIQ::Providers::CloudAutomationManager::ConfigurationManager::ConfigurationProfile",
            :manager_ref => profile["id"].to_s,
            :name        => profile["name"],
            :description => profile["title"],
          }
        end
      end

      def configured_system_inv_to_hashes(configured_systems)
        configured_systems.to_a.collect do |cs|
          {
            :type         => "ManageIQ::Providers::CloudAutomationManager::ConfigurationManager::ConfiguredSystem",
            :manager_ref  => cs["id"].to_s,
            :hostname     => cs["name"],
            :last_checkin => cs["last_compile"],
            :build_state  => cs["build"] ? "pending" : nil,
            :ipaddress    => cs["ip"],
            :mac_address  => cs["mac"],
            :ipmi_present => cs["sp_ip"].present?,
          }
        end
      end
    end
  end
end
