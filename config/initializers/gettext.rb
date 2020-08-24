Vmdb::Gettext::Domains.add_domain(
  'ManageIQ::Providers::IbmTerraform',
  ManageIQ::Providers::IbmTerraform::Engine.root.join('locale').to_s,
  :po
)
