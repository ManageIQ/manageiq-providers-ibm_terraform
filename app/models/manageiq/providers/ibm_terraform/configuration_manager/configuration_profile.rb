class ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfigurationProfile < ::ConfigurationProfile
  include SupportsFeatureMixin
  supports :console

  def console_url
    base_url = provider.default_endpoint.url
    "#{base_url}/cam/templates/#!/templatedetails/#{manager_ref}"
  end
end
