class ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfigurationProfile < ::ConfigurationProfile
  supports :console

  def console_url
    base_url = provider.default_endpoint.url
    "#{base_url}/templates/#!/templatedetails/#{manager_ref}"
  end
end
