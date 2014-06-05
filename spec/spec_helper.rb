require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'bundler/setup'
Bundler.setup

require 'chairs' # and any other gems you need

RSpec.configure do |config|

end
