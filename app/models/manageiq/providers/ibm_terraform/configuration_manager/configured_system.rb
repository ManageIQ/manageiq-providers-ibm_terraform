class ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem < ::ConfiguredSystem
  include ProviderObjectMixin

  def provider_object(connection = nil)
    (connection || connection_source.connect).host(manager_ref)
  end

  def ext_management_system
    manager
  end

  def self.display_name(number = 1)
    n_('Configured System (IBM Terraform)', 'Configured Systems (IBM Terraform)', number)
  end

  private

  def connection_source(options = {})
    options[:connection_source] || manager
  end
end
