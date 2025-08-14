module ManageIQ
  module Providers
    module IbmTerraform
      class Engine < ::Rails::Engine
        isolate_namespace ManageIQ::Providers::IbmTerraform

        config.autoload_paths << root.join('lib')

        def self.vmdb_plugin?
          true
        end

        def self.plugin_name
          _('IBM Terraform Provider')
        end
      end
    end
  end
end
