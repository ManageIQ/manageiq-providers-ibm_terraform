describe ManageIQ::Providers::IbmTerraform::ConfigurationManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_terraform_configuration)
  end

  context "#refresh" do
    before { EvmSpecHelper.create_guid_miq_server_zone }

    let!(:cross_link_vm) { FactoryBot.create(:vm, :ems_ref => "i-0361c15366e550109", :uid_ems => "i-0361c15366e550109") }

    let(:zone) { FactoryBot.create(:zone) }
    let(:params) { {:name => "IbmTerraform for test", :zone_id => zone.id} }
    let(:url) { Rails.application.secrets.cam.try(:[], :url) || 'cam_url' }
    let(:endpoints) do
      identity_url = Rails.application.secrets.cam.try(:[], :identity_url) || 'identity_url'
      [
        {"role" => "default", "url" => "https://#{url}", "verify_ssl" => 0},
        {"role" => "identity", "url" => "https://#{identity_url}", "verify_ssl" => 0},
      ]
    end
    let(:authentications) do
      userid   = Rails.application.secrets.cam.try(:[], :user) || 'CAM_USER'
      password = Rails.application.secrets.cam.try(:[], :password) || 'CAM_PASSWORD'
      [{"authtype" => "default", "userid" => userid, "password" => password}]
    end

    let(:ems) { ManageIQ::Providers::IbmTerraform::ConfigurationManager.create_from_params(params, endpoints, authentications) }
    let(:provider) { ems.provider }

    it "will perform a full refresh" do
      2.times do
        VCR.use_cassette(described_class.name.underscore) do
          EmsRefresh.refresh(ems)
        end

        ems.reload

        assert_ems_counts
        configuration_profile_id = assert_specific_configuration_profile
        assert_specific_configured_system(configuration_profile_id)
      end
    end

    def assert_ems_counts
      expect(ems.configuration_profiles.count).to eq(169)
      expect(ems.configured_systems.count).to     eq(2)
    end

    def assert_specific_configuration_profile
      configuration_profile = ems.configuration_profiles.find_by(:manager_ref => "5d2f6030c068e4001c9bfbb7")
      expect(configuration_profile).to have_attributes(
        :type              => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfigurationProfile",
        :name              => "LAMP stack deployment on AWS",
        :description       => "LAMP - A fully-integrated environment for full stack PHP web development.",
        :target_platform   => "Amazon EC2",
        :supports_console? => true,
        :console_url       => "https://#{url}/templates/#!/templatedetails/5d2f6030c068e4001c9bfbb7"
      )
      configuration_profile.id
    end

    def assert_specific_configured_system(configuration_profile_id)
      configured_system = ems.configured_systems.find_by(:manager_ref => "5eac8d80ed4fa000171eaa23")
      expect(configured_system).to have_attributes(
        :type                     => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem",
        :hostname                 => "demoinstance",
        :vendor                   => "Amazon EC2",
        :configuration_profile_id => configuration_profile_id
      )

      expect(configured_system.counterpart).to eq(cross_link_vm)
    end
  end
end
