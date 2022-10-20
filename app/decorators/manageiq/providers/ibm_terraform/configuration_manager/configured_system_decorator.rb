class ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystemDecorator < ConfiguredSystemDecorator
  VENDOR_ICON_LABEL = {
    "Alibaba Cloud"                => "alibaba",
    "Amazon EC2"                   => "amazon",
    "Google Cloud"                 => "gce",
    "Huawei Cloud"                 => "huawei",
    "IBM"                          => "ibm",
    "IBM Cloud Kubernetes Service" => "ibm_cloud",
    "IBM Cloud Private"            => "ibm_cloud",
    "Microsoft Azure"              => "azure",
    "Nutanix"                      => "nutanix",
    "Openstack"                    => "openstack",
    "Other"                        => "unknown",
    "SoftLayer"                    => "ibm_cloud",
    "Tencent Cloud"                => "tencent",
    "VMware"                       => "vmware",
    "VMware vRealize Automation"   => "vmware",
    "VMware vSphere"               => "vmware",
    nil                            => "unknown",
  }.freeze

  def fileicon
    vendor_icon_label = VENDOR_ICON_LABEL[vendor] || "unknown"
    "svg/vendor-#{vendor_icon_label}.svg"
  end
end
