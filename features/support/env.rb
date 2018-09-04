# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

require 'rubygems'
require 'simplecov'
SimpleCov.start do
  merge_timeout 3600

  add_filter '/spec/'
  add_filter '/initializers/'
  add_filter '/features/'
  add_filter '/factories/'
  add_filter '/config/'

  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Views', 'app/views'
  add_group 'Policies', 'app/policies'
  add_group 'Services', 'app/services'
  add_group 'Lib', 'lib'
end

ENV['RAILS_ENV'] = 'cucumber'

require 'cucumber/rails'
require 'cucumber/rails/capybara/javascript_emulation' # Lets you click links with onclick javascript handlers without using @culerity or @javascript
require 'cucumber/rails/capybara/select_dates_and_times'

require 'webmock/cucumber'

require 'email_spec'
require 'email_spec/cucumber'

require 'cucumber/formatter/unicode'
require 'cucumber/rspec/doubles'
require 'rspec/expectations'

require 'capybara-screenshot/cucumber'

Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara::Screenshot.register_filename_prefix_formatter(:cucumber) do |scenario|
  "screenshot_#{scenario.title.gsub(' ', '-').gsub(/^.*\/spec\//,'')}"
end

# so we can use things like dom_id_for
include ApplicationHelper

DatabaseCleaner.strategy = :transaction
Cucumber::Rails::Database.javascript_strategy = :transaction

APP_CONFIG[:theme] = 'xproject' #lots of tests seem to be broken if we try to use another theme

World(RSpec::ActiveModel::Mocks)
World(RSpec::Mocks::ExampleMethods)

# Make visible for testing
ApplicationController.send(:public, :logged_in?, :current_visitor)

# Note: It is important that this come after cucumber rails db
# config above. We define our own shared connection strategy here
# and it is inteded to override a portion of the shared strategy that
# cucumber rails defines. Incorrect order results in mysql errors.
# More info: https://github.com/concord-consortium/rigse/pull/559
require File.expand_path('../../../spec/spec_helper_common.rb', __FILE__)

include SolrSpecHelper
solr_setup
clean_solar_index
reindex_all
