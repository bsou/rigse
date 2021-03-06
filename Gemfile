require "yaml"
YAML::ENGINE.yamler= "psych" if defined?(YAML::ENGINE)

source "http://rubygems.org"

#### COMMON
source "https://gems.railslts.com" do
  gem 'rails', '~> 3.2.22'
  gem 'actionmailer',     :require => false
  gem 'actionpack',       :require => false
  gem 'activemodel',      :require => false
  gem 'activerecord',     :require => false
  gem 'activeresource',   :require => false
  gem 'activesupport',    :require => false
  gem 'railties',         :require => false
  gem 'railslts-version', :require => false
end
  gem "mysql2",             '~> 0.3.16', :platforms => [:ruby,:mingw]

  gem "devise",               "~>2.1.0"
  gem 'devise-encryptable'

  gem 'omniauth'
  gem 'omniauth-oauth'                      # For schoology integration.
  gem "omniauth-google-oauth2"              # For google login integration.

  gem 'test-unit',            '~> 3.0'

  gem "arrayfields"
  gem 'strong_parameters'
  gem "httparty"

  gem 'rollbar'
  gem 'oj', '~> 2.12.14'

  gem "capistrano",           "~> 2.14.1" #      :require => "capistrano"
  # gem 'capistrano-autoscaling', "0.0.8.5", :git => "git://github.com/concord-consortium/capistrano-autoscaling",  :branch => "concord"
  gem 'capistrano-cowboy'

  gem "aasm",                 "~> 2.2.1"
  gem "will_paginate",        "~> 3.0.0"
  gem "haml",                 "~> 4.0"

  gem "RedCloth",             "~> 4.2.8"
  gem "uuidtools",            "~> 2.1.2"
  gem 'axlsx',                "> 2.5"

  # currently (2017-06-13) axlsx requires an older version of rubyzip, hopefully this will
  # shortly be remedied
  gem 'rubyzip',              "~> 1.2.2"

  gem "prawn",                "~> 0.12.0"
  gem 'prawn_rails',          "~> 0.0.6"

  gem "grit",                 "~> 2.4"
  gem "open4",                "~> 1.0"
  # gem "jnlp",                 "~> 0.8.0"
  # # use a merge of ghazel and tracksimple ar-extensions forks
  # # for mysql2, remove of deprecation warnings, and fixing gemspec so it works with bundler
  # # git "git://github.com/concord-consortium/ar-extensions.git" do
  # #   gem "ar-extensions",        "~> 0.9.3"
  # # end
  gem "activerecord-import",  "~> 0.2.8"
  # gem "fastercsv",            "~> 1.5"
  gem "net-sftp",             "~> 2.0",   :require => "net/sftp"
  gem "redcarpet",            "~> 2.1.1"
  gem "syntax",               "~> 1.0"
  gem "paperclip",            "~> 3.4.0"
  gem "acts-as-taggable-on",  "~> 2.4.1"
  gem "acts_as_list",         "~> 0.1.6"
  gem "nokogiri",             "~> 1.8.0"
  gem 'rdoc',                 "~> 3.9.4"
  # this customization is so the digests or fingerprints are correctly added to the assets even when
  # they are from a theme.
  gem 'themes_for_rails',     :git => 'git://github.com/concord-consortium/themes_for_rails',
           :branch => 'asset-pipeline-only'
  gem 'default_value_for',    "~> 2.0.3"
  gem 'exception_notification', "~> 2.5.2"

  # This gem now contains the prototype_legacy view helpers, and the prototype helpers.
  # The repo name should probably be changed to prototype-rails ?
  gem 'prototype-rails', :git => 'git://github.com/concord-consortium/prototype_legacy_helper.git'

  # gem "in_place_editing",     "~> 1.2.0"
  gem 'in_place_editing',      :git => 'git://github.com/concord-consortium/in_place_editing.git'

  gem 'dynamic_form',         "~> 1.1.4"
  gem 'json',                 "~> 1.8.6"
  # need patched version of calendar_data_select to work in rails 3.1 and higher
  # this is because of the removed RAILS_ROOT constant
  # gem 'calendar_date_select', :git => 'git://github.com/courtland/calendar_date_select'
  gem 'calpicker', :git => 'git://github.com/concord-consortium/calpicker'
  gem 'delayed_job',          "~> 4.1.1"
  gem 'delayed_job_active_record', "~> 4.1.0"
  gem "delayed_job_web"
  gem 'daemons',              "~> 1.1.8"
  gem 'rush',                 :git => 'git://github.com/concord-consortium/rush'
  # this is the old version of aws and is needed by our old version of paperclip
  # we cannot upgrade paperclip until we have rails up to version 4. This uses the AWS
  # namespace.
  gem 'aws-sdk-v1'
  # this is the new version of the aws sdk. It uses the Aws namespace. It is currently used
  # by a rake task to archive old portals
  gem "aws-sdk",              "~> 3"
  gem 'newrelic_rpm', '~> 4.4', '>= 4.4.0.336'
  gem "tinymce-rails",        "~>3.5.6"

# Ideally we pre-compile all asetts and then run production
# with out the asset compiling requirements. But We have dynamic assets
# generated a prototype helper 'calendar_date_picker'
# group :assets do
  gem 'sass-rails' # if running rails 3.1 or greater
  gem 'coffee-rails' # if running rails 3.1 or greater
  gem "compass-rails",          "~> 2.0.4"
  gem "compass-blueprint"
  gem 'uglifier'
  gem 'yui-compressor'
  gem "turbo-sprockets-rails3", "~> 0.3.6"
#      ⬆         ⬆  needed for setup tasks in production and dev :(

  gem 'sunspot_rails'
  gem 'sunspot_solr' # optional pre-packaged Solr distribution
  # TODO ⬆⬆ remove this, and do something better on production deploy

  gem 'sass'
  gem 'font-awesome-rails'
  gem 'virtus',               "~>1.0.3"

  gem 'useragent'  # detect browser types

  gem 'react-rails', '~> 1.7'
  gem 'momentjs-rails', '~>2.17.1'

  source 'https://rails-assets.org' do
    gem 'rails-assets-react-day-picker', '~>5.4.1'
  end

  gem 'nested_form'
  gem 'sanitize'

  # cors is allowed for all groups because cors is always enabled for the interactives/export_model_library
  gem 'rack-cors', :require => 'rack/cors'

  gem 'pundit'

  gem 'jwt'

# see above; for production asset compilation.
# as per http://guides.rubyonrails.org/asset_pipeline.html#precompiling-assets
# when compressing assets without a javascript runtime:
group :production do
  gem 'therubyracer',         "~>0.12.1"
  gem "unicorn"
end

# Feature enabling groups
group :geniverse_wordpress do
  gem "cc_portal_wordpress_integration", :git => "git://github.com/concord-consortium/cc_portal_wordpress_integration"
  # gem "cc_portal_wordpress_integration", :path => "../cc_portal_wordpress_integration"
end

group :geniverse_remote_auth do
  gem "cc_portal_remote_auth", :git => "git://github.com/concord-consortium/cc_portal_remote_auth"
  # gem "cc_portal_remote_auth", :path => "../cc_portal_remote_auth"
end

group :geniverse_backend do
  gem "geniverse_portal_integration", :git => "git://github.com/concord-consortium/geniverse-portal-integration"
  # gem "geniverse_portal_integration", :path => "../geniverse-portal-integration"
end

group :genigames_data do
  gem 'genigames_connector',  '0.0.4', :git => 'git://github.com/concord-consortium/genigames-connector'
  # gem "genigames_connector", :path => "../genigames-connector"
end

group :development do
  gem "rake",                 "~> 0.9.2"
  gem "highline"
  gem "wirble"
  gem "what_methods"
  gem "hirb"
  gem "ruby-debug",   :platforms => [:mri_18, :mingw_18]
  gem "debugger-ruby_core_source", "~> 1.3.8", :platforms => [:mri_19]
  gem "awesome_print"
  gem "interactive_editor"
  gem "ruby-prof"
  gem "spring", "~> 1.7.2" # automatic rails application preloader (similar to Spork)
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false
  gem "sextant"    # adds http://localhost:9000/rails/routes in dev mode
  gem 'xray-rails', '~> 0.1.18' # shows you what is being rendered in your browser with cmd+shift+x
  gem "better_errors", "~> 1.1.0"
  gem "rack-mini-profiler"
  gem "bullet"
  gem "lol_dba"
end

group :test, :cucumber do
  gem "spring-commands-cucumber"
  gem "spring-commands-rspec"
  gem "selenium-webdriver"
  gem "cucumber"
  gem "cucumber-rails",                 :require => false
  gem "database_cleaner"
  gem "capybara"
  gem "rspec"
  gem "rspec-rails"
  gem "rspec-activemodel-mocks"
  gem "rspec-collection_matchers"
  gem "email_spec"
  gem "ci_reporter"
  gem "delorean"
  gem "webmock",                        :require => false
  gem "capybara-mechanize"
  gem 'capybara-screenshot'
  gem "connection_pool"
  gem "json-schema"
  gem 'chromedriver-helper'
end

group :test, :cucumber, :development do
  # this is included in development so the mock data can be loaded into the dev database
  gem "factory_bot"
  gem "guard"
  gem "guard-rspec"
  gem "guard-cucumber"
  gem "remarkable_activerecord",  "~> 3.1.13", :require => nil
  gem "launchy"
  gem "pry"
  gem 'pry-byebug'
  gem 'simplecov', :require => false
end

group :assets do
  gem "jquery-fileupload-rails"
end
