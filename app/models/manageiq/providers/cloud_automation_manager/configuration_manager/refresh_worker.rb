class ManageIQ::Providers::CloudAutomationManager::ConfigurationManager::RefreshWorker < MiqEmsRefreshWorker
  require_nested :Runner

  def self.settings_name
    :ems_refresh_worker_cam_configuration
  end
end
