module ManageIQ::Providers
  module IbmTerraform
    class ConfigurationManager::RefreshParser
      include Vmdb::Logging

      def self.configuration_inv_to_hashes(inv)
        new.configuration_inv_to_hashes(inv)
      end

      def configuration_inv_to_hashes(inv)
        result = {}
        uids = {}

        result[:configuration_profiles], uids[:configuration_profiles] = configuration_profile_inv_to_hashes(inv[:templates])
        result[:configured_systems], uids[:configured_systems] = configured_system_inv_to_hashes(inv[:stacks], uids[:configuration_profiles])

        result
      end

      def configuration_profile_inv_to_hashes(profiles)
        result = []
        uids = {}

        type = "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfigurationProfile".freeze

        profiles.to_a.each do |profile|
          new_result = {
            :type        => type,
            :manager_ref => profile["id"].to_s,
            :name        => profile["name"],
            :description => profile["description"],
          }

          result << new_result
          uids[new_result[:manager_ref]] = new_result
        end

        return result, uids
      end

      def configured_system_inv_to_hashes(configured_systems, configuration_profile_uids)
        result = []
        uids = {}

        type = "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem".freeze

        configured_systems.to_a.each do |cs|
          new_result = {
            :type         => type,
            :manager_ref  => cs["id"].to_s,
            :hostname     => cs["name"],
            :last_checkin => cs["created_at"],
            :build_state  => cs["build"],
            :mac_address  => cs["status"],
            :configuration_profile => configuration_profile_uids[cs["templateId"]]
          }

          result << new_result
          uids[new_result[:manager_ref]] = new_result
        end

        return result, uids
      end
    end
  end
end
