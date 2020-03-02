class ManageIQ::Providers::CloudAutomationManager::ConfigurationManager < ManageIQ::Providers::ConfigurationManager
  require_nested :ConfigurationProfile
  require_nested :ConfiguredSystem
  require_nested :Refresher
  require_nested :RefreshParser
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
             :to => ManageIQ::Providers::CloudAutomationManager::Provider
  end

  def self.ems_type
    @ems_type ||= "cam_configuration".freeze
  end

  def self.description
    @description ||= "Cloud Automation Manager Configuration".freeze
  end

  def image_name
    "cam_configuration"
  end

  def self.display_name(number = 1)
    n_('Configuration Manager (Cloud Automation Manager)', 'Configuration Managers (Cloud Automation Manager)', number)
  end
end
