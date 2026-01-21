# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'spec_helper'
require_relative '../config/environment'
require 'rspec/rails'
require 'geocoder'

# Safety check: never run specs in production
abort('The Rails environment is running in production mode!') if Rails.env.production?

# Load support files (helpers, shared examples, matchers, etc.)
Rails.root.glob('spec/support/**/*.rb').sort.each { |file| require file }

# Ensure test schema is up to date
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s
end

RSpec.configure do |config|
  # Fixtures (only if you actually use them)
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # Use transactions for speed & isolation
  config.use_transactional_fixtures = true

  # Infer spec type from file location (models, services, controllers, etc.)
  config.infer_spec_type_from_file_location!

  # Cleaner backtraces
  config.filter_rails_from_backtrace!
  # config.filter_gems_from_backtrace('gem_name')

  RSpec.configure do |config|
    config.include FactoryBot::Syntax::Methods
  end

  # Configure Geocoder to use the test lookup
  Geocoder.configure(lookup: :test)

  # Make any geocoding query return the same lat/lng
  Geocoder::Lookup::Test.set_default_stub(
    [
      { latitude: -23.561414, longitude: -46.655881 }
    ]
  )

  #
  # === Custom helpers ===
  #
  config.include Spec::ModelHelpers
end
