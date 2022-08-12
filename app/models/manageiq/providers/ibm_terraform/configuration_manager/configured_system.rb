class ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem < ::ConfiguredSystem
  supports :native_console do
    _('No Cloud Pak URL') if provider.cpd_endpoint.url.blank?
  end

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

  def console_url
    base_url = provider.cpd_endpoint.url
    stack_id = orchestration_stack&.ems_ref

    "#{base_url}/cam/instances/#!/instanceDetails/#{stack_id}" if stack_id && base_url
  end

  private

  def connection_source(options = {})
    options[:connection_source] || manager
  end
end
