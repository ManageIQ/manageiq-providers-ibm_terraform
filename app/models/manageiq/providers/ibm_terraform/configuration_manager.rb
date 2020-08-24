class ManageIQ::Providers::IbmTerraform::ConfigurationManager < ManageIQ::Providers::ConfigurationManager
  require_nested :ConfigurationProfile
  require_nested :ConfiguredSystem
  require_nested :Refresher
  require_nested :RefreshWorker

  include ProcessTasksMixin
  delegate :authentication_check,
           :authentication_status,
           :authentication_status_ok?,
           :connect,
           :verify_credentials,
           :with_provider_connection,
           :to => :provider

  class << self
    delegate :params_for_create,
             :verify_credentials,
             :to => ManageIQ::Providers::IbmTerraform::Provider
  end

  def self.ems_type
    @ems_type ||= "ibm_terraform_configuration".freeze
  end

  def self.description
    @description ||= "IBM Terraform Configuration".freeze
  end

  def image_name
    "ibm_terraform_configuration"
  end

  def self.display_name(number = 1)
    n_('Configuration Manager (IBM Terraform)', 'Configuration Managers (IBM Terraform)', number)
  end
end
