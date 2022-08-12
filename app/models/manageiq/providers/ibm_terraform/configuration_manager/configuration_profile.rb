class ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfigurationProfile < ::ConfigurationProfile
  supports :native_console

  def console_url
    base_url = provider.cpd_endpoint.url
    "#{base_url}/cam/templates/#!/templatedetails/#{manager_ref}"
  end
end
