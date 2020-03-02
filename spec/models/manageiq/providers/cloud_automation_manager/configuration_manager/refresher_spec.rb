describe ManageIQ::Providers::CloudAutomationManager::ConfigurationManager::Refresher do
  it ".ems_type" do
    expect(described_class.ems_type).to eq(:cam_configuration)
  end

  context "#refresh" do
    let(:provider) do
      url = Rails.application.secrets.cam.try(:[], 'url') || 'CLOUD_AUTOMATION_MANAGER_URL'
      FactoryBot.create(:provider_cam, :url => url).tap do |p|
        userid   = Rails.application.secrets.cam.try(:[], 'user') || 'CLOUD_AUTOMATION_MANAGER_USER'
        password = Rails.application.secrets.cam.try(:[], 'password') || 'CLOUD_AUTOMATION_MANAGER_PASSWORD'

        p.update_authentication(:default => {:userid => userid, :password => password})
      end
    end

    let(:ems) { provider.configuration_manager }

    it "will perform a full refresh" do
      2.times do
        VCR.use_cassette(described_class.name.underscore) do
          EmsRefresh.refresh(ems)
        end
      end
    end
  end
end
