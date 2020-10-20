class ManageIQ::Providers::IbmTerraform::ConfigurationManager::ConfiguredSystemDecorator < ConfiguredSystemDecorator
  VENDOR_ICON_LABEL = {
    "Amazon EC2"                   => "amazon",
    "Google Cloud"                 => "gce",
    "Huawei Cloud"                 => "huawei",
    "IBM"                          => "ibm",
    "IBM Cloud Kubernetes Service" => "ibm",
    "IBM Cloud Private"            => "ibm",
    "Microsoft Azure"              => "azure",
    "Nutanix"                      => "nutanix",
    "Openstack"                    => "openstack",
    "Other"                        => "unknown",
    "SoftLayer"                    => "ibm",
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
