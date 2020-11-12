class ManageIQ::Providers::IbmTerraform::Inventory::Parser::ConfigurationManager < ManageIQ::Providers::IbmTerraform::Inventory::Parser
  def parse
    configuration_profiles
    orchestration_stacks
    configured_systems
  end

  def configuration_profiles
    collector.templates.each do |template|
      persister.configuration_profiles.build(
        :manager_ref     => template["id"].to_s,
        :name            => template["name"],
        :description     => template["description"],
        :target_platform => template.dig("manifest", "template_provider")
      )
    end
  end

  def orchestration_stacks
    collector.stacks.each do |stack|
      persister.orchestration_stacks.build(
        :ems_ref     => stack["id"].to_s,
        :name        => stack["name"],
        :description => stack["templateName"],
        :status      => stack["status"],
        :created_at  => stack["created_at"],
        :updated_at  => stack["lastUpdatedAt"]
      )
    end
  end

  # Sample IaasResources - virtual_machines response from  API
  # [{
  #     "type": "virtual_machine",
  #     "name": "aws_instance.web-server",
  #     "stackId": "5ee8dd8b6143d40017c2ee3c",
  #     "provider": "Amazon EC2",
  #     "idFromProvider": "i-0d59174316cafb2x0",
  #     "typeFromProvider": "aws_instance",
  #     "module_path": [
  #         "root"
  #     ],
  #     "consolelinks": [
  #         "https://console.aws.amazon.com/ec2/v2/home"
  #     ],
  #     "ipaddresses": [
  #         "18.215.xxx.yyy",
  #         "172.31.xx.yy"
  #     ],
  #     "stacks": {
  #         "templateId": "5ee8ddde6143d40017c2ee46"
  #     },
  #     "details": {
  #         "name": "demoinstance"
  #     },
  #     "tainted": false,
  #     "tenantId": "fbb9ab6a-b54d-43d4-9200-6d950700588f",
  #     "namespaceId": "acme",
  #     "namespaceMapping": true,
  #     "id": "5ee8ddde6143d40017c2ee45"
  # }]
  def configured_systems
    collector.virtual_machines.each do |virtual_machine|
      virtual_instance_ref  = get_virtual_instance_ref(virtual_machine)
      counterpart           = find_counterpart_vm(virtual_machine["provider"], virtual_instance_ref)
      template_id           = virtual_machine.dig("stacks", "templateId")
      configuration_profile = persister.configuration_profiles.lazy_find(template_id.to_s) if template_id
      stack_id              = virtual_machine["stackId"]
      orchestration_stack   = persister.orchestration_stacks.lazy_find(stack_id.to_s) if stack_id

      persister.configured_systems.build(
        :manager_ref           => virtual_machine["id"].to_s,
        :name                  => get_hostname(virtual_machine),
        :ipaddress             => virtual_machine["ipaddresses"]&.first,
        :vendor                => virtual_machine["provider"],
        :virtual_instance_ref  => virtual_instance_ref,
        :counterpart           => counterpart,
        :configuration_profile => configuration_profile,
        :orchestration_stack   => orchestration_stack
      )
    end
  end

  private

  def get_hostname(virtual_machine)
    vm_provider = virtual_machine["provider"]
    if vm_provider == "Amazon EC2"
      virtual_machine.dig("details", "tags.Name")
    elsif vm_provider == "IBM"
      virtual_machine.dig("details", "hostname")
    else
      virtual_machine.dig("details", "name")
    end
  end

  def find_counterpart_vm(vm_provider, virtual_instance_ref)
    return nil if virtual_instance_ref.nil?

    if vm_provider == "Microsoft Azure"
      persister.vms.lazy_find({:ems_ref => virtual_instance_ref}, {:ref => :by_ems_ref})
    else
      persister.vms.lazy_find({:uid_ems => virtual_instance_ref}, {:ref => :by_uid_ems})
    end
  end

  # The Azure virtual instance reference(from Terrafrom) will be modified to match the format used by Azure Provider.
  # INPUT: /subscriptions/0e0a4200-8719-4849-bb0b-abcde/resourceGroups/virtualmachine-tm-071b00e5-rg/providers/Microsoft.Compute/virtualMachines/virtualmachine-tm-vm
  # OUTPUT: 0e0a4200-8719-4849-bb0b-abcde/virtualmachine-tm-071b00e5-rg/microsoft.compute/virtualmachines/virtualmachine-tm-vm
  def get_virtual_instance_ref(virtual_machine)
    virtual_instance_ref = virtual_machine["idFromProvider"]
    return nil if virtual_instance_ref.nil?

    vm_provider = virtual_machine["provider"]
    if vm_provider == "Microsoft Azure"
      virtual_instance_ref.downcase.gsub(/\/subscriptions\/|\/resourcegroups\b|\/providers\b/, '')
    else
      virtual_instance_ref
    end
  end
end
