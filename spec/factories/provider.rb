FactoryBot.define do
  factory :provider_cam, :class => "ManageIQ::Providers::CloudAutomationManager::Provider", :parent => :provider do
    sequence(:url) { |n| "example_#{seq_padded_for_sorting(n)}.com" }
  end
end
