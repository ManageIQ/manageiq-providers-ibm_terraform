describe ManageIQ::Providers::IbmTerraform::ConfigurationManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_terraform_configuration)
  end

  context "#refresh" do
    before { EvmSpecHelper.create_guid_miq_server_zone }

    let!(:cross_link_aws_vm) { FactoryBot.create(:vm, :ems_ref => "i-0361c15366e550109", :uid_ems => "i-0361c15366e550109") }
    let!(:cross_link_azure_vm) { FactoryBot.create(:vm, :ems_ref => "0e0a4287-8719-4849-bb0b-5242e4507709/virtualmachine-eff8898f-rg/microsoft.compute/virtualmachines/virtualmachine-vm", :uid_ems => "b70ad672-e302-4124-b771-f7f2e64dc6f8") }
    let!(:cross_link_vmware_vm) { FactoryBot.create(:vm, :ems_ref => "vm-41321", :uid_ems => "421bb662-77fb-a66e-3fd9-ff0cdc7578b1") }

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
        orchestration_stack_id = assert_specific_orchestration_stack
        assert_specific_aws_configured_system(configuration_profile_id, orchestration_stack_id)
        assert_specific_azure_configured_system
        assert_specific_vmware_configured_system
      end
    end

    def assert_ems_counts
      expect(ems.configuration_profiles.count).to eq(169)
      expect(ems.configured_systems.count).to     eq(4)
    end

    def assert_specific_configuration_profile
      configuration_profile = ems.configuration_profiles.find_by(:manager_ref => "5d2f6030c068e4001c9bfbb7")
      expect(configuration_profile).to have_attributes(
        :type              => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfigurationProfile",
        :name              => "LAMP stack deployment on AWS",
        :description       => "LAMP - A fully-integrated environment for full stack PHP web development.",
        :target_platform   => "Amazon EC2",
        :supports_console? => true,
        :console_url       => "https://#{url}/cam/templates/#!/templatedetails/5d2f6030c068e4001c9bfbb7"
      )
      configuration_profile.id
    end

    def assert_specific_orchestration_stack
      orchestration_stack = ems.orchestration_stacks.find_by(:ems_ref => "5eac8d41ed4fa000171eaa1b")
      expect(orchestration_stack).to have_attributes(
        :type        => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::OrchestrationStack",
        :name        => "nodejs",
        :description => "Node.js on a Single VM on AWS"
      )
      orchestration_stack.id
    end

    def assert_specific_aws_configured_system(configuration_profile_id, orchestration_stack_id)
      aws_configured_system = ems.configured_systems.find_by(:manager_ref => "5eac8d80ed4fa000171eaa23")
      expect(aws_configured_system).to have_attributes(
        :type                     => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem",
        :hostname                 => "demoinstance",
        :vendor                   => "Amazon EC2",
        :configuration_profile_id => configuration_profile_id,
        :orchestration_stack_id   => orchestration_stack_id,
        :supports_console?        => true,
        :console_url              => "https://#{url}/cam/instances/#!/instanceDetails/5eac8d41ed4fa000171eaa1b"
      )

      expect(aws_configured_system.counterpart).to eq(cross_link_aws_vm)
    end

    def assert_specific_azure_configured_system
      azure_configured_system = ems.configured_systems.find_by(:manager_ref => "5fad64b05456fc0018395307")
      expect(azure_configured_system).to have_attributes(
        :type                 => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem",
        :vendor               => "Microsoft Azure",
        :virtual_instance_ref => "0e0a4287-8719-4849-bb0b-5242e4507709/virtualmachine-eff8898f-rg/microsoft.compute/virtualmachines/virtualmachine-vm"
      )

      expect(azure_configured_system.counterpart).to eq(cross_link_azure_vm)
    end

    def assert_specific_vmware_configured_system
      vmware_configured_system = ems.configured_systems.find_by(:manager_ref => "5f9c52b4c4e5ae00180fb96a")
      expect(vmware_configured_system).to have_attributes(
        :type                 => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem",
        :vendor               => "VMware vSphere",
        :virtual_instance_ref => "421bb662-77fb-a66e-3fd9-ff0cdc7578b1"
      )

      expect(vmware_configured_system.counterpart).to eq(cross_link_vmware_vm)
    end
  end
end
