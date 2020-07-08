# frozen_string_literal: true

require 'bundler/setup'
require 'railway_ipc'
require 'rake'
require 'fileutils'
require 'rails_helper'
require 'factory_bot'

ENV['RAILWAY_RABBITMQ_CONNECTION_URL'] = 'amqp://guest:guest@localhost:5672'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].sort.each do |file|
  next if file.include?('support/rails_app')

  require file
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :active_record
    with.library :active_model
  end
end

RSpec.configure do |config|
  # Setup Test DB to use with support Rails app
  config.before(:suite) do
    FactoryBot.find_definitions
    RailwayIpc::RailsTestDB.create
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) { RailwayIpc::RailsTestDB.destroy }

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FactoryBot::Syntax::Methods
  config.include RailwayIpc::SpecHelpers
end
