module ManageIQ::Providers
  module CloudAutomationManager
    class ConfigurationManager::Refresher < ManageIQ::Providers::BaseManager::Refresher
      def parse_legacy_inventory(manager)
        manager.with_provider_connection do |connection|
          data = collect_configuration_inventory(connection)
          ConfigurationManager::RefreshParser.configuration_inv_to_hashes(data)
        end
      end

      def save_inventory(manager, target, hashes)
        EmsRefresh.save_configuration_manager_inventory(manager, hashes, target)
      end

      private

      def collect_configuration_inventory(connection)
        {}
      end
    end
  end
end
