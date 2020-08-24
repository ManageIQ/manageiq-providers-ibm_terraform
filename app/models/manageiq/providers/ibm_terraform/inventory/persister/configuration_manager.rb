class ManageIQ::Providers::IbmTerraform::Inventory::Persister::ConfigurationManager < ManageIQ::Providers::IbmTerraform::Inventory::Persister
  def initialize_inventory_collections
    add_collection(configuration, :configuration_profiles)
    add_collection(configuration, :configured_systems)
  end
end
