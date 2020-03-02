module ManageIQ
  module Providers
    module CloudAutomationManager
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::CloudAutomationManager

        config.autoload_paths << root.join('lib').to_s

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('ManageIQ Providers Cloud Automation Manager')
        end
      end
    end
  end
end
