if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].each { |f| require f }

require "manageiq-providers-ibm_terraform"

VCR.configure do |config|
  config.ignore_hosts 'codeclimate.com' if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::IbmTerraform::Engine.root, 'spec/vcr_cassettes')

  secrets = Rails.application.secrets
  secrets.ibm_terraform.keys.each do |secret|
    config.define_cassette_placeholder(secrets.ibm_terraform_defaults[secret]) { secrets.ibm_terraform[secret] }
  end
end
