# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  minimum_coverage 50
end

require 'bundler/setup'
require 'jekyll-baserow-headless-cms'
require 'webmock/rspec'

# Disable external connections
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    # Reset environment variables
    ENV.delete('BASEROW_TOKEN')
    ENV.delete('BASEROW_API_URL')
    ENV.delete('BASEROW_TEST_TABLE')
  end
end

# Helper to load fixture files
def fixture_path(filename)
  File.join(File.dirname(__FILE__), 'fixtures', filename)
end

def load_fixture(filename)
  JSON.parse(File.read(fixture_path(filename)))
end
