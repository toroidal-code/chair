require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'bundler/setup'
Bundler.setup

require 'factory_girl'

require 'chairs' # and any other gems you need

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  # additional factory_girl configuration

  config.before(:suite) do
    FactoryGirl.lint
  end
end
