set :stages, %w(development staging production)
set :default_stage, "development"
# require File.expand_path("#{File.dirname(__FILE__)}/../vendor/gems/capistrano-ext-1.2.1/lib/capistrano/ext/multistage")
require 'capistrano/ext/multistage'

#############################################################
#  Application
#############################################################

set :application, "rites"
set :deploy_to, "/web/rites.concord.org"

#############################################################
#  Settings
#############################################################

default_run_options[:pty] = true
ssh_options[:forward_agent] = true
set :use_sudo, true
set :scm_verbose, true
set :rails_env, "production" 
  
#############################################################
#  Git
#############################################################

set :scm, :git
set :branch, "production"
set :git_enable_submodules, 1
# wondering if we can do something special for this? create
# a special deploy user on github?
set(:scm_user) do
  Capistrano::CLI.ui.ask "Enter your git username: "
end
set(:scm_passphrase) do
  Capistrano::CLI.password_prompt( "Enter your git password: ")
end
set :repository, "git://github.com/stepheneb/rigse.git"
set :deploy_via, :remote_cache

#############################################################
#  DB
#############################################################


namespace :db do
  desc 'Dumps the production database to db/production_data.sql on the remote server'
  task :remote_db_dump, :roles => :db, :only => { :primary => true } do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} db:dump --trace" 
  end
  
  desc 'Loads the production database in db/production_data.sql on the remote server'
  task :remote_db_load, :roles => :db, :only => { :primary => true } do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} db:load --trace" 
  end

  desc 'Downloads db/production_data.sql from the remote production environment to your local machine'
  task :remote_db_download, :roles => :db, :only => { :primary => true } do  
    download("#{deploy_to}/#{current_dir}/db/production_data.sql", "db/production_data.sql", :via => :sftp)
  end
  
  desc 'Uploads db/production_data.sql to the remote production environment from your local machine'
  task :remote_db_upload, :roles => :db, :only => { :primary => true } do  
    upload("db/production_data.sql", "#{deploy_to}/#{current_dir}/db/production_data.sql", :via => :sftp)
  end

  desc 'Cleans up data dump file'
  task :remote_db_cleanup, :roles => :db, :only => { :primary => true } do
    execute_on_servers(options) do |servers|
      self.sessions[servers.first].sftp.connect do |tsftp|
        tsftp.remove! "#{deploy_to}/#{current_dir}/db/production_data.sql" 
      end
    end
  end 

  desc 'Dumps, downloads and then cleans up the production data dump'
  task :fetch_remote_db do
    remote_db_dump
    remote_db_download
    remote_db_cleanup
  end
  
  desc 'Uploads, inserts, and then cleans up the production data dump'
  task :push_remote_db do
    remote_db_upload
    remote_db_load
    remote_db_cleanup
  end
  

end

namespace :deploy do
  #############################################################
  #  Passenger
  #############################################################
      
  # Restart passenger on deploy
  desc "Restarting passenger with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    sudo "touch #{current_path}/tmp/restart.txt"
  end
  
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with passenger"
    task t, :roles => :app do ; end
  end

  desc "setup a new version of rigse from-scratch using rake task of similar name"
  task :from_scratch do
    run "cd #{deploy_to}/current; rake rigse:setup:force_new_rigse_from_scratch"
  end
  
  desc "link in some shared resources, such as database.yml"
  task :shared_symlinks do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/settings.yml #{release_path}/config/settings.yml"
    run "ln -nfs #{shared_path}/config/sds.yml #{release_path}/config/sds.yml"
    run "ln -nfs #{shared_path}/config/mailer.yml #{release_path}/config/mailer.yml"
    run "ln -nfs #{shared_path}/config/initializers/site_keys.rb #{release_path}/config/initializers/site_keys.rb"
    run "ln -nfs #{shared_path}/public/otrunk-examples #{release_path}/public/otrunk-examples"
    run "ln -nfs #{shared_path}/engines/portal/config/nces_data #{release_path}/vendor/plugins/portal/config/nces_data"
  end
    
  desc "install required gems for application"
  task :install_gems do
    sudo "sh -c 'cd #{deploy_to}/current; rake gems:install'"
  end
  
  desc "set correct file permissions of the deployed files"
  task :set_permissions, :roles => :app do
    sudo "chown -R apache.users #{deploy_to}"
    sudo "chmod -R g+rw #{deploy_to}"
  end
  
end

#############################################################
#  IMPORT
#############################################################

namespace :import do
  
  desc 'import grade span expectations from files in config/rigse_data/'
  task :import_gses_from_file, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:setup:import_gses_from_file --trace" 
  end
  
  desc 'erase and import ITSI activities from the ITSI DIY'
  task :erase_and_import_itsi_activities, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:import:erase_and_import_itsi_activities --trace" 
  end

  desc 'erase and import ITSI Activities from the ITSI DIY collected as Units from the CCPortal'
  task :erase_and_import_ccp_itsi_units, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:import:erase_and_import_ccp_itsi_units --trace" 
  end

  desc "generate names for existing MavenJnlpServers that don't have them"
  task :generate_names_for_maven_jnlp_servers, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:jnlp:generate_names_for_maven_jnlp_servers --trace" 
  end

  desc "generate MavenJnlp family of resources from jnlp servers in settings.yml"
  task :generate_maven_jnlp_family_of_resources, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:jnlp:generate_maven_jnlp_family_of_resources --trace" 
  end
  
  desc "delete all the MavenJnlp resources"
  task :delete_maven_jnlp_resources, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:jnlp:delete_maven_jnlp_resources --trace" 
  end

  desc"Generate OtrunkExamples:: Rails models from the content in the otrunk-examples dir."
  task :generate_otrunk_examples_rails_models, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:import:generate_otrunk_examples_rails_models --trace" 
  end

  desc"Delete the otrunk-example models (Rails models)."
  task :delete_otrunk_example_models, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:import:delete_otrunk_example_models --trace" 
  end

  desc"Create git clone of otrunk-examples in <shared_path>/public/otrunk-examples"
  task :create_git_clone_of_otrunk_examples, :roles => :app do
    run "cd #{shared_path} && " +
      "mkdir -p public && " +
      "cd public && " +
      "git clone git://github.com/stepheneb/otrunk-examples.git"
  end

  desc"Download nces data files from NCES websites"
  task :download_nces_data, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} portal:setup:download_nces_data --trace" 
  end

  desc "Import nces data from files: config/nces_data/* -- uses APP_CONFIG[:states_and_provinces] if defined to filter on states"
  task :nces_data_from_files, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} portal:setup:import_nces_from_file --trace" 
  end

  desc"reload the default probe and vendor_interface configurations."
  task :reload_probe_configurations, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} db:backup:load_probe_configurations --trace" 
  end

end

#############################################################
#  DELETE
#############################################################

namespace :delete do
  desc "delete all the MavenJnlp resources"
  task :delete_maven_jnlp_resources, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:jnlp:delete_maven_jnlp_resources --trace" 
  end
  
end

#############################################################
#  Convert
#############################################################

namespace :convert do
  desc 'wrap orphaned activities in a parent investigation'
  task :wrap_orphaned_activities_in_investigations, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:make:investigations --trace" 
  end

  desc 'set new grade_span_expectation attribute: gse_key'
  task :set_gse_keys, :roles => :db, :only => { :primary => true } do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:convert:set_gse_keys --trace" 
  end

  desc 'find page_elements whithout owners and reclaim them'
  task :reclaim_page_elements, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:convert:reclaim_elements --trace" 
  end
  
  desc 'transfer any Investigations owned by the anonymous user to the site admin user'
  task :transfer_investigations_owned_by_anonymous, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:convert:transfer_investigations_owned_by_anonymous --trace"
  end
  
  desc 'deep set user ownership on all investigations'
  task :deep_set_user_on_all_investigations, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:convert:run_deep_set_user_on_all_investigations --trace"
  end
  
  desc 'clean up teacher notes owned by the wrong user'
  task :clean_teacher_notes, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:convert:clean_teacher_notes --trace"
  end

  desc 'add the author role to all users who have authored an Investigation'
  task :add_author_role_to_authors, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:convert:add_author_role_to_authors --trace"
  end

  desc "set publication_status to 'draft' for all Investigations without publication_status"
  task :set_publication_status_to_draft, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:convert:pub_status --trace"
  end

  desc "Data Collectors with a static graph_type to a static attribute; DataCollectors with a graph_type_id of nil to Sensor"
  task :data_collectors_with_invalid_graph_types, :roles => :app do
    run "cd #{deploy_to}/#{current_dir} && " +
      "rake RAILS_ENV=#{rails_env} rigse:convert:data_collectors_with_invalid_graph_types --trace"
  end

end

after 'deploy:update_code', 'deploy:shared_symlinks'
after 'deploy:symlink', 'deploy:set_permissions'
