$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'arugula'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
end
