class ManageIQ::Providers::IbmTerraform::ConfigurationManager < ManageIQ::Providers::ConfigurationManager
  include ProcessTasksMixin
  delegate :authentications,
           :authentications=,
           :authentication_check,
           :authentication_status,
           :authentication_status_ok?,
           :connect,
           :endpoints,
           :endpoints=,
           :url,
           :url=,
           :name=,
           :verify_credentials,
           :with_provider_connection,
           :to => :provider

  belongs_to :provider, :autosave => true, :dependent => :destroy

  has_many :orchestration_stacks, :dependent => :destroy, :foreign_key => "ems_id"
  has_many :computer_systems, :through => :configured_systems
  has_many :hardwares, :through => :computer_systems

  class << self
    delegate :params_for_create,
             :verify_credentials,
             :to => ManageIQ::Providers::IbmTerraform::Provider
  end

  supports :create

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

  def name
    "#{provider.name} Configuration Manager"
  end

  def provider
    super || ensure_provider
  end

  private

  def ensure_provider
    build_provider.tap { |p| p.configuration_manager = self }
  end
end
