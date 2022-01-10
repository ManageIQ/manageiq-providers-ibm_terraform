class ManageIQ::Providers::IbmTerraform::Inventory::Persister::ConfigurationManager < ManageIQ::Providers::IbmTerraform::Inventory::Persister
  def initialize_inventory_collections
    add_collection(configuration, :configuration_profiles)
    add_collection(configuration, :configured_systems)
    add_collection(configuration, :orchestration_stacks)
    add_collection(configuration, :computer_systems) { |b| b.add_properties(:manager_ref => %i[managed_entity]) }
    add_collection(configuration, :hardwares) { |b| b.add_properties(:manager_ref => %i[computer_system]) }
    add_cross_provider_vms
  end

  def add_cross_provider_vms
    add_collection(configuration, :vms, {}, {:without_sti => true}) do |builder|
      builder.add_properties(
        :parent         => nil,
        :arel           => Vm,
        :strategy       => :local_db_find_references,
        :secondary_refs => {:by_uid_ems => %i[uid_ems], :by_ems_ref => %i[ems_ref]}
      )
    end
  end
end
