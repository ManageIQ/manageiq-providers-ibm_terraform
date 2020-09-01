class ManageIQ::Providers::IbmTerraform::Inventory::Parser::ConfigurationManager < ManageIQ::Providers::IbmTerraform::Inventory::Parser
  def parse
    configuration_profiles
    configured_systems
  end

  def configuration_profiles
    collector.templates.each do |template|
      persister.configuration_profiles.build(
        :manager_ref => template["id"].to_s,
        :name        => template["name"],
        :description => template["description"]
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
  #     "tainted": false,
  #     "tenantId": "fbb9ab6a-b54d-43d4-9200-6d950700588f",
  #     "namespaceId": "acme",
  #     "namespaceMapping": true,
  #     "id": "5ee8ddde6143d40017c2ee45"
  # }]
  def configured_systems
    collector.virtual_machines.each do |virtual_machine|
      persister.configured_systems.build(
        :manager_ref          => virtual_machine["id"].to_s,
        :name                 => virtual_machine["name"],
        :ipaddress            => virtual_machine["ipaddresses"]&.first,
        :virtual_instance_ref => virtual_machine["idFromProvider"]
      )
    end
  end
end
