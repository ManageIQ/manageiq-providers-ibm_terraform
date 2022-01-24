class ManageIQ::Providers::IbmTerraform::Inventory::Persister::ConfigurationManager < ManageIQ::Providers::IbmTerraform::Inventory::Persister
  def initialize_inventory_collections
    add_collection(configuration, :configuration_profiles)
    add_collection(configuration, :configured_systems)
    add_collection(configuration, :orchestration_stacks)
    add_collection(configuration, :computer_systems) { |b| b.add_properties(:manager_ref => %i[managed_entity]) }
    add_collection(configuration, :hardwares) { |b| b.add_properties(:manager_ref => %i[computer_system]) }
    add_collection(configuration, :cross_link_vms)
  end
end
