class ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfigurationProfile < ::ConfigurationProfile
  supports :management_console do
    _('No Cloud Pak URL') if provider.cpd_endpoint.url.blank?
  end

  def console_url
    base_url = provider.cpd_endpoint.url
    "#{base_url}/cam/templates/#!/templatedetails/#{manager_ref}" if base_url
  end
end
