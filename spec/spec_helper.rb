require "bundler/setup"
require "railway_ipc"
require 'rake'
require 'fileutils'
require 'rails_helper'

ENV["RAILWAY_RABBITMQ_CONNECTION_URL"] = "amqp://guest:guest@localhost:5672"

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each do |file|
  next if file.include?('support/rails_app')

  require file
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Setup Test DB to use with support Rails app
  config.before(:suite) { RailwayIpc::RailsTestDB.create }
  config.after(:suite) { RailwayIpc::RailsTestDB.destroy }
end
