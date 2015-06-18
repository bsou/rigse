#############################################################
#  Application
#############################################################

set :deploy_to, "/web/portal"
set :branch, "itsisu-staging"
set :default_environment, {
  'LABBOOK_PROVIDER_URL' => 'https://labbook.concord.org/'
}

#############################################################
#  Servers
#############################################################

set :domain, "itsi-aws.staging.concord.org"
server domain, :app, :web
role :db, domain, :primary => true

namespace :db do
 # desc 'Loads the production database in db/production_data.sql on the remote server'
 # task :remote_db_load, :roles => :db, :only => { :primary => true } do
 #   puts "This task is disabled for the production environment"
 # end
 #  
 # desc 'Uploads db/production_data.sql to the remote production environment from your local machine'
 # task :remote_db_upload, :roles => :db, :only => { :primary => true } do  
 #   puts "This task is disabled for the production environment"
 # end
 # 
 # desc 'Uploads, inserts, and then cleans up the production data dump'
 # task :push_remote_db do
 #   puts "This task is disabled for the production environment"
 # end
end