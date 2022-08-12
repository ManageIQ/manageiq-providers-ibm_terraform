describe ManageIQ::Providers::IbmTerraform::ConfigurationManager do
  before { EvmSpecHelper.create_guid_miq_server_zone }

  let(:zone) { FactoryBot.create(:zone) }
  let(:params) { {:name => "IbmTerraform for test", :zone_id => zone.id} }
  let(:endpoints) do
    [
      {"role" => "default", "url" => "https://cam.dev.multicloudops.io", "verify_ssl" => 0},
      {"role" => "identity", "url" => "https://cp-console.dev.multicloudops.io", "verify_ssl" => 0},
      {"role" => "cpd", "url" => "https://cpd-cp4waiops.dev.multicloudops.io", "verify_ssl" => 0},
    ]
  end
  let(:authentications) do
    [{"authtype" => "default", "userid" => "admin", "password" => "password"}]
  end

  describe "create configuration manager tests" do
    it "#create_from_params test" do
      config_manager = described_class.create_from_params(params, endpoints, authentications)

      # verify the configuration manager and the provider are created properly
      expect(config_manager.name).to eq("IbmTerraform for test Configuration Manager")
      expect(config_manager.zone_id).to eq(zone.id)

      expect(config_manager.provider.name).to eq("IbmTerraform for test")
      expect(config_manager.provider.endpoints.count).to eq(3)

      # verify the configuration manager can be found in db by zone_id
      expect(described_class.where(:zone_id => zone.id)).to exist
    end
  end

  describe "update configuration manager tests" do
    let(:ems) { described_class.create_from_params(params, endpoints, authentications) }
    let(:provider) { ems.provider }

    it "#edit_with_params test" do
      provider_name = "IbmTerraform2"
      params = {:name => provider_name, :zone_id => zone.id}
      endpoints = [
        {"role" => "default", "url" => "https://cam.dev.multicloudops.io", "verify_ssl" => 0},
        {"role" => "identity", "url" => "https://cp-console.dev.multicloudops.io", "verify_ssl" => 0},
        {"role" => "cpd", "url" => "https://cpd-cp4waiops.dev.multicloudops.io", "verify_ssl" => 0},
      ]
      authentications = [
        {"authtype" => "default", "userid" => "admin", "password" => "password"}
      ]

      ems.edit_with_params(params, endpoints, authentications)
      provider.reload

      expect(provider.name).to eq(provider_name)
      expect(ems.zone_id).to eq(zone.id)
    end
  end
end
