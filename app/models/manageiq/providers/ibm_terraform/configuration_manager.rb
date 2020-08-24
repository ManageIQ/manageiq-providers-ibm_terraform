class ManageIQ::Providers::IbmTerraform::ConfigurationManager < ManageIQ::Providers::ConfigurationManager
  require_nested :ConfigurationProfile
  require_nested :ConfiguredSystem
  require_nested :Refresher
  require_nested :RefreshWorker

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
           :verify_credentials,
           :with_provider_connection,
           :to => :provider

  belongs_to :provider, :autosave => true, :dependent => :destroy

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

  def self.create_from_params(params, endpoints, authentications)
    new(params).tap do |ems|
      endpoints.each { |endpoint| ems.assign_nested_endpoint(endpoint) }
      authentications.each { |authentication| ems.assign_nested_authentication(authentication) }

      ems.provider.save!
      ems.save!
    end
  end

  def edit_with_params(params, endpoints, authentications)
    tap do |ems|
      transaction do
        # Remove endpoints/attributes that are not arriving in the arguments above
        ems.endpoints.where.not(:role => nil).where.not(:role => endpoints.map { |ep| ep['role'] }).delete_all
        ems.authentications.where.not(:authtype => nil).where.not(:authtype => authentications.map { |au| au['authtype'] }).delete_all

        ems.assign_attributes(params)
        ems.endpoints = endpoints.map(&method(:assign_nested_endpoint))
        ems.authentications = authentications.map(&method(:assign_nested_authentication))

        ems.provider.save!
        ems.save!
      end
    end
  end
  delegate :name=, :zone, :zone=, :zone_id, :zone_id=, :to => :provider

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
