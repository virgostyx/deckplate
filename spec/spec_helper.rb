require "simplecov"
SimpleCov.start do
  enable_coverage :branch
  add_filter "/spec/"
  minimum_coverage line: 95 if ENV["CI"]
end

ENV["RAILS_ENV"] = "test"
require_relative "dummy/config/environment"
require "rspec/rails"

Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.infer_spec_type_from_file_location!
  config.disable_monkey_patching!
end
