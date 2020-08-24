class ManageIQ::Providers::IbmTerraform::Inventory::Parser::ConfigurationManager < ManageIQ::Providers::IbmTerraform::Inventory::Parser
  def parse
    configuration_profiles
    configured_systems
  end

  def configuration_profiles
    collector.templates.each do |template|
      persister.configuration_profiles.build(
        :manager_ref => template["id"].to_s,
        :name        => template["name"],
        :description => template["description"]
      )
    end
  end

  def configured_systems
    collector.stacks.each do |stack|
      template_ref = stack["templateId"].to_s

      persister.configured_systems.build(
        :manager_ref           => stack["id"].to_s,
        :hostname              => stack["name"],
        :last_checkin          => stack["created_at"],
        :build_state           => stack["build"],
        :mac_address           => stack["status"],
        :configuration_profile => persister.configuration_profiles.lazy_find(template_ref)
      )
    end
  end
end
