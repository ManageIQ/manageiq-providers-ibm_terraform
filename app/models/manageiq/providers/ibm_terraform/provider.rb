class ManageIQ::Providers::IbmTerraform::Provider < ::Provider
  has_one :configuration_manager,
          :foreign_key => "provider_id",
          :class_name  => "ManageIQ::Providers::IbmTerraform::ConfigurationManager",
          :dependent   => :destroy,
          :autosave    => true

  has_many :endpoints, :as => :resource, :dependent => :destroy, :autosave => true

  delegate :url,
           :url=,
           :to => :default_endpoint

  delegate :url,
           :url=,
           :to => :identity_endpoint, :prefix => "identity"

  delegate :url,
           :url=,
           :to => :cpd_endpoint, :prefix => "cpd"

  virtual_column :url, :type => :string, :uses => :endpoints

  before_validation :ensure_managers

  validates :name,         :presence => true, :uniqueness => true
  validates :url,          :presence => true
  validates :identity_url, :presence => true

  def self.description
    @description ||= "IBM Terraform Configuration".freeze
  end

  def self.params_for_create
    {
      :fields => [
        {
          :component => 'sub-form',
          :name      => 'endpoints-subform',
          :id        => 'endpoints-subform',
          :title     => _("Endpoint"),
          :fields    => [
            {
              :component              => 'validate-provider-credentials',
              :name                   => 'authentications.default.valid',
              :id                     => 'authentications.default.valid',
              :skipSubmit             => true,
              :isRequired             => true,
              :validationDependencies => %w[type zone_id],
              :fields                 => [
                {
                  :component  => "text-field",
                  :name       => "endpoints.default.url",
                  :id         => "endpoints.default.url",
                  :label      => _("Managed Services URL"),
                  :helperText => _("Managed Services URL. e.g. https://cam.apps.mydomain.com"),
                  :isRequired => true,
                  :validate   => [{:type => "required"}]
                },
                {
                  :component  => "text-field",
                  :name       => "endpoints.identity.url",
                  :id         => "endpoints.identity.url",
                  :label      => _("IBM Cloud Pak console"),
                  :helperText => _("IBM Cloud Pak console URL. e.g. https://cp-console.apps.mydomain.com"),
                  :isRequired => true,
                  :validate   => [{:type => "required"}]
                },
                {
                  :component  => "text-field",
                  :name       => "endpoints.cpd.url",
                  :id         => "endpoints.cpd.url",
                  :label      => _("IBM Cloud Pak URL"),
                  :helperText => _("IBM Cloud Pak URL. e.g. https://cpd-cp4waiops.apps.mydomain.com"),
                  :isRequired => true,
                  :validate   => [{:type => "required"}]
                },
                {
                  :component    => "select",
                  :name         => "endpoints.default.verify_ssl",
                  :id           => "endpoints.default.verify_ssl",
                  :label        => _("SSL verification"),
                  :dataType     => "integer",
                  :isRequired   => true,
                  :initialValue => OpenSSL::SSL::VERIFY_PEER,
                  :options      => [
                    {
                      :label => _('Do not verify'),
                      :value => OpenSSL::SSL::VERIFY_NONE,
                    },
                    {
                      :label => _('Verify'),
                      :value => OpenSSL::SSL::VERIFY_PEER,
                    },
                  ]
                },
                {
                  :component  => "text-field",
                  :name       => "authentications.default.userid",
                  :id         => "authentications.default.userid",
                  :label      => _("Username"),
                  :helperText => _("Should have privileged access, such as administrator."),
                  :isRequired => true,
                  :validate   => [{:type => "required"}]
                },
                {
                  :component  => "password-field",
                  :name       => "authentications.default.password",
                  :id         => "authentications.default.password",
                  :label      => _("Password"),
                  :type       => "password",
                  :isRequired => true,
                  :validate   => [{:type => "required"}]
                },
              ],
            },
          ],
        },
      ]
    }
  end

  # Verify Credentials
  # args: {
  #  "endpoints" => {
  #    "identity" => {
  #       "url" => nil
  #    },
  #    "default" => {
  #       "url" => nil,
  #       "verify_ssl" => nil
  #    },
  #  },
  #  "authentications" => {
  #     "default" => {
  #       "userid" => nil,
  #       "password" => nil,
  #     }
  #   }
  # }
  def self.verify_credentials(args)
    default_authentication = args.dig("authentications", "default")
    identity_url = args.dig("endpoints", "identity", "url")
    verify_mode = args.dig("endpoints", "default", "verify_ssl")

    userid   = default_authentication["userid"]
    password = ManageIQ::Password.try_decrypt(default_authentication["password"])

    !!raw_connect(identity_url, userid, password, verify_mode)
  end

  def self.raw_connect(base_url, username, password, verify_mode)
    url      = URI.parse(base_url)
    url.path = "/idprovider/v1/auth/identitytoken"
    use_ssl  = url.scheme == "https"

    require "net/http"
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

  def identity_endpoint
    identity_endpoint = endpoints.detect { |e| e.role == "identity" }
    identity_endpoint || endpoints.build(:role => "identity")
  end

  def cpd_endpoint
    cpd_endpoint = endpoints.detect { |e| e.role == "cpd" }
    cpd_endpoint || endpoints.build(:role => "cpd")
  end

  def connect(options = {})
    auth_type = options[:auth_type]
    raise "no credentials defined" if self.missing_credentials?(auth_type)

    verify_ssl = options[:verify_ssl] || self.verify_ssl
    base_url   = options[:identity_url] || identity_url
    username   = options[:username] || authentication_userid(auth_type)
    password   = options[:password] || authentication_password(auth_type)

    self.class.raw_connect(base_url, username, password, verify_ssl)
  end

  def verify_credentials(auth_type = nil, options = {})
    verify_ssl = options[:verify_ssl] || self.verify_ssl
    !!self.class.raw_connect(identity_url, *auth_user_pwd, verify_ssl)
  rescue SocketError, Errno::ECONNREFUSED, RestClient::ResourceNotFound, RestClient::InternalServerError => err
    raise MiqException::MiqUnreachableError, err.message, err.backtrace
  rescue RestClient::Unauthorized => err
    raise MiqException::MiqInvalidCredentialsError, err.message, err.backtrace
  end

  private

  def ensure_managers
    build_configuration_manager unless configuration_manager
    configuration_manager.provider = self

    if zone_id_changed?
      configuration_manager.enabled = Zone.maintenance_zone&.id != zone_id
    end
  end
end
