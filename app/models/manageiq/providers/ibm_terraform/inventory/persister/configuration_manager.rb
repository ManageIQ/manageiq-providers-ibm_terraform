class ManageIQ::Providers::IbmTerraform::Inventory::Persister::ConfigurationManager < ManageIQ::Providers::IbmTerraform::Inventory::Persister
  def initialize_inventory_collections
    add_collection(configuration, :configuration_profiles)
    add_collection(configuration, :configured_systems)
    add_collection(configuration, :orchestration_stacks)

    add_cross_provider_vms
  end

  def add_cross_provider_vms
    add_collection(configuration, :vms) do |builder|
      builder.add_properties(
        :parent      => nil,
        :arel        => Vm,
        :strategy    => :local_db_find_references,
        :manager_ref => %i[uid_ems]
      )
    end
  end
end
