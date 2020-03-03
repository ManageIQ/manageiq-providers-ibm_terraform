class ManageIQ::Providers::CloudAutomationManager::Provider < ::Provider
  has_one :configuration_manager,
          :foreign_key => "provider_id",
          :class_name  => "ManageIQ::Providers::CloudAutomationManager::ConfigurationManager",
          :dependent   => :destroy,
          :autosave    => true

  has_many :endpoints, :as => :resource, :dependent => :destroy, :autosave => true

  delegate :url,
           :url=,
           :to => :default_endpoint

  virtual_column :url, :type => :string, :uses => :endpoints

  before_validation :ensure_managers

  validates :name, :presence => true, :uniqueness => true
  validates :url,  :presence => true

  def self.description
    @description ||= "Cloud Automation Manager".freeze
  end

  def self.params_for_create
    @params_for_create ||= {
      :title  => "Configure #{description}",
      :fields => [
        {
          :component  => "text-field",
          :name       => "endpoints.default.base_url",
          :label      => "URL",
          :isRequired => true,
          :validate   => [{:type => "required-validator"}]
        },
        {
          :component  => "text-field",
          :name       => "endpoints.default.username",
          :label      => "User",
          :isRequired => true,
          :validate   => [{:type => "required-validator"}]
        },
        {
          :component  => "text-field",
          :name       => "endpoints.default.password",
          :label      => "Password",
          :type       => "password",
          :isRequired => true,
          :validate   => [{:type => "required-validator"}]
        },
        {
          :component => "checkbox",
          :name      => "endpoints.default.verify_ssl",
          :label     => "Verify SSL"
        }
      ]
    }.freeze
  end

  # Verify Credentials
  # args: {
  #  "endpoints" => {
  #    "default" => {
  #      "base_url" => nil,
  #      "username" => nil,
  #      "password" => nil,
  #      "verify_ssl" => nil
  #    }
  #  }
  # }
  def self.verify_credentials(args)
    default_endpoint = args.dig("endpoints", "default")
    base_url, username, password, verify_ssl = default_endpoint&.values_at("base_url", "username", "password", "verify_ssl")
    verify_ssl = verify_ssl ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
    !!raw_connect(base_url, username, password, verify_ssl)
  end

  def self.raw_connect(base_url, username, password, verify_ssl)
    url         = URI.parse(base_url)
    url.port    = 8443
    url.path    = "/v1/auth/identitytoken"
    use_ssl     = url.scheme == "https"
    verify_mode = verify_ssl ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

    response = Net::HTTP.start(url.hostname, url.port, :use_ssl => use_ssl, :verify_mode => verify_mode) do |http|
      body    = {
        "grant_type" => "password",
        "username"   => username,
        "password"   => password,
        "scope"      => "openid"
      }

      headers = {"Content-Type" => "application/json"}

      http.post(url, body.to_json, headers)
    end

    "Bearer #{JSON.parse(response.body)["access_token"]}"
  end

  def connect(options = {})
    auth_type = options[:auth_type]
    raise "no credentials defined" if self.missing_credentials?(auth_type)

    verify_ssl = options[:verify_ssl] || self.verify_ssl
    base_url   = options[:url] || url
    username   = options[:username] || authentication_userid(auth_type)
    password   = options[:password] || authentication_password(auth_type)

    self.class.raw_connect(base_url, username, password, verify_ssl)
  end

  def verify_credentials(auth_type = nil, options = {})
    uri = URI.parse(url) unless url.blank?

    !!self.class.raw_connect(url, *auth_user_pwd, false)
  rescue SocketError, Errno::ECONNREFUSED, RestClient::ResourceNotFound, RestClient::InternalServerError => err
    raise MiqException::MiqUnreachableError, err.message, err.backtrace
  rescue RestClient::Unauthorized => err
    raise MiqException::MiqInvalidCredentialsError, err.message, err.backtrace
  end

  private

  def ensure_managers
    build_configuration_manager unless configuration_manager
    configuration_manager.name    = "#{name} Configuration Manager"
    configuration_manager.zone_id = zone_id
  end

  def self.refresh_ems(provider_ids)
    EmsRefresh.queue_refresh(Array.wrap(provider_ids).collect { |id| [base_class, id] })
  end
end
