$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'paperclip-googledrive'
Dir[File.join('./spec/support/**/*.rb')].each { |f| require f }
require 'rspec'
require 'pry'
require 'active_record'
require 'active_record/version'
require 'active_support'
require 'active_support/core_ext'
require 'pathname'
# require 'activerecord-import'

# require 'webmock/rspec'
# require 'vcr'

Pry.config.prompt = proc { |obj, nest_level, _| "ppc-gd> " }

# VCR.configure do |c|
#   c.cassette_library_dir = "spec/fixtures/cassettes"
#   c.hook_into :webmock
# end

#FIXTURES_DIR = File.join(File.dirname(__FILE__), "fixtures")
config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(config['test'])
Paperclip.options[:logger] = ActiveRecord::Base.logger
ActiveSupport::Deprecation.silenced = true

RSpec.configure do |config|
  config.include ModelReconstruction
end
