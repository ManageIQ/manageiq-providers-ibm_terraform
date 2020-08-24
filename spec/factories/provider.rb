FactoryBot.define do
  factory :provider_ibm_terraform, :class => "ManageIQ::Providers::IbmTerraform::Provider", :parent => :provider do
    sequence(:url) { |n| "example_#{seq_padded_for_sorting(n)}.com" }
  end
end
