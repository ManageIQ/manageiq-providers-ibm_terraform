Vmdb::Gettext::Domains.add_domain(
  'ManageIQ::Providers::CloudAutomationManager',
  ManageIQ::Providers::CloudAutomationManager::Engine.root.join('locale').to_s,
  :po
)
