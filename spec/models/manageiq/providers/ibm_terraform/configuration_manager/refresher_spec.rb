describe ManageIQ::Providers::IbmTerraform::ConfigurationManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:ibm_terraform_configuration)
  end

  context "#refresh" do
    before { EvmSpecHelper.create_guid_miq_server_zone }

    let!(:cross_link_aws_vm) { FactoryBot.create(:vm, :ems_ref => "i-0361c15366e550109", :uid_ems => "i-0361c15366e550109") }
    let!(:cross_link_azure_vm) { FactoryBot.create(:vm, :ems_ref => "0e0a4287-8719-4849-bb0b-5242e4507709/virtualmachine-eff8898f-rg/microsoft.compute/virtualmachines/virtualmachine-vm", :uid_ems => "b70ad672-e302-4124-b771-f7f2e64dc6f8") }
    let!(:cross_link_vmware_vm) { FactoryBot.create(:vm, :ems_ref => "vm-44564", :uid_ems => "421b4acc-4a8a-828b-e483-9f6b9177df67") }

    let(:zone) { FactoryBot.create(:zone) }
    let(:params) { {:name => "IbmTerraform for test", :zone_id => zone.id} }
    let(:url) { Rails.application.secrets.ibm_terraform[:url] }
    let(:endpoints) do
      identity_url = Rails.application.secrets.ibm_terraform[:identity_url]
      [
        {"role" => "default", "url" => "https://#{url}", "verify_ssl" => 0},
        {"role" => "identity", "url" => "https://#{identity_url}", "verify_ssl" => 0},
      ]
    end
    let(:authentications) do
      userid   = Rails.application.secrets.ibm_terraform[:user]
      password = Rails.application.secrets.ibm_terraform[:password]
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
        assert_specific_alicloud_configured_system
        assert_specific_aws_configured_system(configuration_profile_id, orchestration_stack_id)
        assert_aws_configured_system_hostname_with_multiple_tags
        assert_specific_azure_configured_system
        assert_specific_vmware_configured_system
        assert_specific_ibm_vpc_configured_system
      end
    end

    def assert_ems_counts
      expect(ems.configuration_profiles.count).to eq(169)
      expect(ems.configured_systems.count).to     eq(7)
    end

    def assert_specific_configuration_profile
      configuration_profile = ems.configuration_profiles.find_by(:manager_ref => "5d2f6030c068e4001c9bfbb7")
      expect(configuration_profile).to have_attributes(
        :type              => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfigurationProfile",
        :name              => "LAMP stack deployment on AWS",
        :description       => "LAMP - A fully-integrated environment for full stack PHP web development.",
        :target_platform   => "Amazon EC2",
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

    def assert_specific_alicloud_configured_system
      alicloud_configured_system = ems.configured_systems.find_by(:manager_ref => "601d9b41a2914c00180e78ee")
      expect(alicloud_configured_system).to have_attributes(
        :type                 => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem",
        :vendor               => "Alibaba Cloud",
        :virtual_instance_ref => "i-0xi3on88xoglv783iflg"
      )

      expect(alicloud_configured_system.computer_system).not_to be   nil
      expect(alicloud_configured_system.hardware).not_to be          nil
      expect(alicloud_configured_system.hardware.cpu_total_cores).to eq(1)
      expect(alicloud_configured_system.hardware.memory_mb).to       eq(2048)

      alicloud_configured_system_computer_system = ComputerSystem.where(:managed_entity_id => alicloud_configured_system.id.to_s)
      expect(alicloud_configured_system_computer_system.size).to eq(1)

      alicloud_configured_system_hardware = Hardware.where(:computer_system => alicloud_configured_system_computer_system)
      expect(alicloud_configured_system_hardware.size).to eq(1)
    end

    def assert_specific_aws_configured_system(configuration_profile_id, orchestration_stack_id)
      aws_configured_system = ems.configured_systems.find_by(:manager_ref => "5eac8d80ed4fa000171eaa23")
      expect(aws_configured_system).to have_attributes(
        :type                     => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem",
        :hostname                 => "demoinstance",
        :vendor                   => "Amazon EC2",
        :configuration_profile_id => configuration_profile_id,
        :orchestration_stack_id   => orchestration_stack_id,
        :console_url              => "https://#{url}/cam/instances/#!/instanceDetails/5eac8d41ed4fa000171eaa1b"
      )

      expect(aws_configured_system.counterpart).to eq(cross_link_aws_vm)
    end

    def assert_aws_configured_system_hostname_with_multiple_tags
      aws_configured_system = ems.configured_systems.find_by(:manager_ref => "5fb677b9ae457000181dd463")
      expect(aws_configured_system).to have_attributes(
        :type     => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem",
        :hostname => "agostino-hybrid-1",
        :vendor   => "Amazon EC2"
      )

      expect(aws_configured_system.computer_system).to be   nil
      expect(aws_configured_system.hardware).to be          nil

      aws_configured_system_computer_system = ComputerSystem.where(:managed_entity_id => aws_configured_system.id.to_s)
      expect(aws_configured_system_computer_system.size).to eq(0)
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
      vmware_configured_system = ems.configured_systems.find_by(:manager_ref => "601d9c79a2914c00180e78f8")
      expect(vmware_configured_system).to have_attributes(
        :type                 => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem",
        :vendor               => "VMware vSphere",
        :virtual_instance_ref => "421b4acc-4a8a-828b-e483-9f6b9177df67"
      )

      expect(vmware_configured_system.counterpart).to eq(cross_link_vmware_vm)

      expect(vmware_configured_system.computer_system).not_to be   nil
      expect(vmware_configured_system.hardware).not_to be          nil
      expect(vmware_configured_system.hardware.cpu_total_cores).to eq(1)
      expect(vmware_configured_system.hardware.memory_mb).to       eq(1024)

      vmware_configured_system_computer_system = ComputerSystem.where(:managed_entity_id => vmware_configured_system.id.to_s)
      expect(vmware_configured_system_computer_system.size).to eq(1)

      vmware_configured_system_hardware = Hardware.where(:computer_system => vmware_configured_system_computer_system)
      expect(vmware_configured_system_hardware.size).to eq(1)
    end

    def assert_specific_ibm_vpc_configured_system
      ibm_configured_system = ems.configured_systems.find_by(:manager_ref => "5fc7b3070300a80018e3c192")
      expect(ibm_configured_system).to have_attributes(
        :type                 => "ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystem",
        :hostname             => "web-server-vsi",
        :vendor               => "IBM",
        :virtual_instance_ref => "0757_099e516f-f489-455b-a459-10b73d50d04d"
      )
    end
  end
end
