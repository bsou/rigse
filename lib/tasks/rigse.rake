namespace :rigse do
  
  JRUBY = defined? RUBY_ENGINE && RUBY_ENGINE == 'jruby'

  def jruby_system_command
    JRUBY ? "jruby -S" : ""
  end

  def jruby_run_command
    JRUBY ? "jruby " : "ruby "
  end
  
  PLUGIN_LIST = {
    :acts_as_taggable_on_steroids => 'http://svn.viney.net.nz/things/rails/plugins/acts_as_taggable_on_steroids',
    :attachment_fu => 'git://github.com/technoweenie/attachment_fu.git',
    :bundle_fu => 'git://github.com/timcharper/bundle-fu.git',
    :fudge_form => 'git://github.com/JimNeath/fudge_form.git',
    :haml => 'git://github.com/nex3/haml.git',
    :jrails => 'git://github.com/aaronchi/jrails.git',
    :paperclip => 'git://github.com/thoughtbot/paperclip.git',
    :salty_slugs => 'git://github.com/norbauer/salty_slugs.git',
    :shoulda => 'git://github.com/thoughtbot/shoulda.git',
    :spawn => 'git://github.com/tra/spawn.git',
    :workling => 'git://github.com/purzelrakete/workling.git'
  }
  
  
  desc "display info about the site admin user"
  task :display_site_admin => :environment do
    puts User.site_admin.to_yaml
  end
  
  
  #######################################################################
  #
  # List all plugins available to quick install
  #
  #######################################################################  
  desc 'List all plugins available to quick install'
  task :install do
    puts "\nAvailable Plugins\n=================\n\n"
    plugins = PLUGIN_LIST.keys.sort_by { |k| k.to_s }.map { |key| [key, PLUGIN_LIST[key]] }
    
    plugins.each do |plugin|
      puts "#{plugin.first.to_s.gsub('_', ' ').capitalize.ljust(30)} rake rigse:install:#{plugin.first.to_s}\n"
    end
    puts "\n"
  end
  
  namespace :install do
    PLUGIN_LIST.each_pair do |key, value|
      task key do
        system('script/plugin', 'install', value, '--force')
      end
    end
  end

  namespace :setup do
    
    require 'highline/import'
    require 'fileutils'
    
    def rails_file_path(*args)
      File.join([RAILS_ROOT] + args)
    end


    desc "setup initial probe_type for data_collectors that don't have one"
    task :set_probe_type_for_data_collectors => :environment do
      DataCollector.find(:all).each do |dc| 
        if pt = ProbeType.find_by_name(dc.y_axis_label)
          dc.probe_type = pt
          dc.save
        end
      end
    end
    
    #######################################################################
    #
    # Raise an error unless the RAILS_ENV is development,
    # unless the user REALLY wants to run in another mode.
    #
    #######################################################################
    desc "Raise an error unless the RAILS_ENV is development"
    task :development_environment_only => :environment  do
      unless RAILS_ENV == 'development'
        puts "\nNormally you will only be running this task in development mode.\n"
        puts "You are running in #{RAILS_ENV} mode.\n"
        unless agree("Are you sure you want to do this?  (y/n)", true)
          raise "task stopped by user"
        end
      end
    end
    
    #######################################################################
    #
    # Regenerate the REST_AUTH_SITE_KEY 
    #
    #######################################################################
    desc "regenerate the REST_AUTH_SITE_KEY -- all passwords will become invalid"
    task :regenerate_rest_auth_site_key => :environment do
      
      gem "uuidtools", '>= 2.0.0'
      require 'uuidtools'
      
      puts <<HEREDOC

This task will re-generate a REST_AUTH_SITE_KEY and update
the file config/initializers/site_keys.rb.

Completing this will invalidate existing passwords. Users will
need to complete the "forgot password" process to revalidate
their passwords even though their actual password hasn't changed.

If the application is running it will need to be restarted for
this change to take effect.

HEREDOC
      
      if agree("Do you want to do this?  (y/n)", true)
        site_keys_path = rails_file_path(%w{config initializers site_keys.rb})
        site_key = UUIDTools::UUID.timestamp_create.to_s

        site_keys_rb = <<HEREDOC
REST_AUTH_SITE_KEY = '#{site_key}'
REST_AUTH_DIGEST_STRETCHES = 10
HEREDOC

        File.open(site_keys_path, 'w') {|f| f.write site_keys_rb }
        FileUtils.chmod 0660, site_keys_path
      end
    end
    
    
    #######################################################################
    #
    # New from scratch
    #
    #######################################################################
    desc "setup a new rigse instance"
    task :new_rigse_from_scratch => :environment do
      db_config = ActiveRecord::Base.configurations[RAILS_ENV]

      Rake::Task['rigse:setup:development_environment_only'].invoke
      
      puts <<HEREDOC

This task will drop the existing rigse database: #{db_config['database']}, rebuild it from scratch, 
and install default users.
  
HEREDOC
      if agree("Do you want to do this?  (y/n)", true)
        begin
          Rake::Task['db:drop'].invoke
        rescue StandardException
        end
        Rake::Task['db:create'].invoke
        Rake::Task['db:migrate'].invoke
        Rake::Task['rigse:setup:default_users_roles'].invoke
        Rake::Task['rigse:setup:create_additional_users'].invoke
        Rake::Task['rigse:setup:import_gses_from_file'].invoke
        Rake::Task['rigse:setup:assign_vernier_golink_to_users'].invoke
        Rake::Task['db:backup:load_probe_configurations'].invoke
        Rake::Task['rigse:setup:assign_vernier_golink_to_users'].invoke
        Rake::Task['rigse:jnlp:generate_maven_jnlp_family_of_resources'].invoke
        Rake::Task['rigse:import:generate_otrunk_examples_rails_models'].invoke
  
        puts <<HEREDOC

You can now start the application in develelopment mode by running this command:

  #{jruby_run_command}script/server

You can re-edit the initial configuration parameters by running the
setup script again:

  #{jruby_run_command}config/setup.rb

You can re-create the database from scratch and setup default users 
again by running this rake task again:

  #{jruby_system_command} rake rigse:setup:new_rigse_from_scratch

If you have access to an ITSI database you can also import ITSI activities 
into RITES by running this rake task:

  #{jruby_system_command} rake rigse:import:erase_and_import_itsi_activities

* if you are developing locally and are using the same database for both development and production
  environments the ITSI import will run much faster in production mode:

  RAILS_ENV=production #{jruby_system_command} rake rigse:import:erase_and_import_itsi_activities

If you have access to a CCPortal database that indexes ITSI Activities into sequenced Units 
you can also import these ITSI activities into RITES Investigations by running this rake task:

  #{jruby_system_command} rake rigse:import:erase_and_import_ccp_itsi_units

* if you are developing locally and are using the same database for both development and production
  environments the ITSI import will run much faster in production mode:

  RAILS_ENV=production #{jruby_system_command} rake rigse:import:erase_and_import_ccp_itsi_units


HEREDOC
      end
    end
    
    def display_user(user)
      puts <<HEREDOC

       login: #{user.login}
       email: #{user.email}
  first_name: #{user.first_name}
   last_name: #{user.last_name}

HEREDOC
    end
  
    def edit_user(user)
      require 'highline/import'
      user.login =                 ask("            login: ") {|q| q.default = user.login}
      user.email =                 ask("            email: ") {|q| q.default = user.email}
      user.first_name =            ask("       first name: ") {|q| q.default = user.first_name}
      user.last_name =             ask("        last name: ") {|q| q.default = user.last_name}
      user.password =              ask("         password: ") {|q| q.default = user.password; q.echo = "*"}
      user.password_confirmation = ask(" confirm password: ") {|q| q.default = user.password_confirmation; q.echo = "*"}
      user
    end


    #######################################################################
    #
    # Create additional users
    #
    #######################################################################
    #
    # additional_users.yml is a YAML file that includes a list of users
    # to create when setting up a new instance. The salt and crypted_password
    # are specified for these users.
    #
    # A role specification is optional.
    #
    # Here's an example of how to create and additional_users.yml file:
    #
    # additional_users = { "stephen" =>
    #   { "role"=>"admin", 
    #     "first_name"=>"Stephen", 
    #     "last_name"=>"Bannasch", 
    #     "email"=>"stephen.bannasch@gmail.com"}
    #   }
    # File.open(File.join(RAILS_ROOT, %w{config additional_users.yml}), 'w') {|f| YAML.dump(additional_users, f)}
    # 
    # The additional users will be created but each one will need to go to the
    # forgot password link to actually get a working password:
    #
    #   http://rigse-dev.concord.org/rigse/forgot_password
    #
    desc "Create additional users from additional_users.yml file."
    task :create_additional_users => :environment do
      begin
        path = File.join(RAILS_ROOT, %w{config additional_users.yml})
        additional_users = YAML::load(IO.read(path))
        puts "\nCreating additional users ...\n\n"
        pw = User.make_token
        additional_users.each do |user_config|
          puts "  #{user_config[1]['role']} #{user_config[0]}: #{user_config[1]['first_name']} #{user_config[1]['last_name']}, #{user_config[1]['email']}"
          if u = User.find_by_email(user_config[1]['email'])
            puts "  *** user: #{u.name} already exists ...\n"
          else
            u = User.create(:login => user_config[0], 
              :first_name => user_config[1]['first_name'], 
              :last_name => user_config[1]['last_name'], 
              :email => user_config[1]['email'], 
              :password => pw, 
              :password_confirmation => pw)
            u = User.find_by_login(user_config[0])
            u.register!
            u.activate!
            role_title = user_config[1]['role']
            if role_title
              role = Role.find_by_title(role_title)
              u.roles << role
            end
          end
        end
        puts "\n"
      rescue SystemCallError => e
        # puts e.class
        # puts "#{path} not found"
      end
    end


    #######################################################################
    #
    # Assign Vernier go!Link as default vendor_interface for users
    # without a vendor_interface.
    #
    #######################################################################
    desc "Assign Vernier go!Link as default vendor_interface for users without a vendor_interface."
    task :assign_vernier_golink_to_users => :environment do
      interface = VendorInterface.find_by_short_name('vernier_goio')
      User.find(:all).each do |u|
        unless u.vendor_interface
          u.vendor_interface = interface
          u.save
        end
      end
    end
   
    #######################################################################
    #
    # Delete existing users and restore default users and roles
    #
    #######################################################################   
    desc "Delete existing users and restore default users and roles"
    task :delete_users_and_restore_default_users_roles => :environment do
      # The TRUNCATE cammand works in mysql to effectively empty the database and reset 
      # the autogenerating primary key index ... not certain about other databases
      puts
      puts "deleted: #{ActiveRecord::Base.connection.delete("TRUNCATE `#{User.table_name}`")} from User"
      Rake::Task['rigse:setup:default_users_roles'].invoke
      Rake::Task['rigse:setup:create_additional_users'].invoke
    end
   
   
    #######################################################################
    #
    # Create default users, roles, district, school, course, and class
    #
    #######################################################################   
    desc "Create default users and roles"
    task :default_users_roles => :environment do

      puts <<HEREDOC

This task creates six roles (if they dont already exist):

  admin
  manager
  researcher
  author
  member
  guest

It creates one user with an admin role. 

  The default values for the admin user are taken from config/settings.yml.
  Edit the values in this file if you want to specify a different default admin user.

In addition it creates seven more default users with these login names and the 
default password: 'password'. You can change the dfault password if you wish.

  manager
  researcher
  author
  member
  teacher
  student
  anonymous

You can edit the default settings for all of these users.

It also creates one published Investigation owned by the Author user.

It also create a default School District :#{APP_CONFIG[:site_district]}.
and a default School in that district: #{APP_CONFIG[:site_school]}.

The default Teacher user will be a Teacher in the school: #{APP_CONFIG[:site_school]} and
will be teaching a course named 'default course' and a class in that course named 'default class'


First creating admin user account for: #{APP_CONFIG[:admin_email]} from site parameters in config/settings.yml:
HEREDOC

      roles_in_order = [
        admin_role = Role.find_or_create_by_title('admin'),
        manager_role = Role.find_or_create_by_title('manager'),
        researcher_role = Role.find_or_create_by_title('researcher'),
        author_role = Role.find_or_create_by_title('author'),
        member_role = Role.find_or_create_by_title('member'),
        guest_role = Role.find_or_create_by_title('guest')
      ]
      
      all_roles = Role.find(:all)
      unused_roles = all_roles - roles_in_order
      if unused_roles.length > 0
        unused_roles.each { |role| role.destroy }
      end
      
      # to make sure the list is ordered correctly in case a new role is added
      roles_in_order.each_with_index do |role, i|
        role.insert_at(i)
      end

      default_user_list = [
        admin_user = User.find_or_create_by_login(:login => APP_CONFIG[:admin_login], 
          :first_name => APP_CONFIG[:admin_first_name], :last_name => APP_CONFIG[:admin_last_name],
          :email => APP_CONFIG[:admin_email], 
          :password => "password", :password_confirmation => "password"),

        manager_user = User.find_or_create_by_login(:login => 'manager', 
          :first_name => 'Manager', :last_name => 'User', 
          :email => 'manager@concord.org', 
          :password => "password", :password_confirmation => "password"),

        researcher_user = User.find_or_create_by_login(:login => 'researcher', 
          :first_name => 'Researcher', :last_name => 'User', 
          :email => 'researcher@concord.org', 
          :password => "password", :password_confirmation => "password"),

        author_user = User.find_or_create_by_login(:login => 'author', 
          :first_name => 'Author', :last_name => 'User', 
          :email => 'author@concord.org', 
          :password => "password", :password_confirmation => "password"),

        member_user = User.find_or_create_by_login(:login => 'member', 
          :first_name => 'Member', :last_name => 'User', 
          :email => 'member@concord.org', 
          :password => "password", :password_confirmation => "password"),

        anonymous_user = User.find_or_create_by_login(:login => "anonymous", 
          :first_name => "Anonymous", :last_name => "User",
          :email => "anonymous@concord.org", 
          :password => "password", :password_confirmation => "password"),

        teacher_user = User.find_or_create_by_login(:login => 'teacher', 
          :first_name => 'Teacher', :last_name => 'User', 
          :email => 'teacher@concord.org', 
          :password => "password", :password_confirmation => "password"),

        student_user = User.find_or_create_by_login(:login => 'student', 
          :first_name => 'Student', :last_name => 'User', 
          :email => 'student@concord.org', 
          :password => "password", :password_confirmation => "password")
      ]

      edit_user_list = default_user_list - [anonymous_user]
      
      edit_user_list.each { |user| display_user(user) }
      unless agree("Accept defaults? (y/n) ", true)
        edit_user_list.each do |user|
          user = edit_user(user)  if agree("Edit #{user.login}?  (y/n) ", true)
        end
      end

      default_user_list.each do |user|
        user.save!
        unless user.state == 'active'
          user.register!
          user.activate!
        end
        user.roles.clear
      end

      admin_user.add_role('admin')
      manager_user.add_role('manager')
      researcher_user.add_role('researcher')
      member_user.add_role('member')
      anonymous_user.add_role('guest')
      
      default_investigation = DefaultInvestigation.create_default_investigation_for_user(author_user)

      site_district = RitesPortal::District.find_or_create_by_name(APP_CONFIG[:site_district])
      site_district.description = "This is a virtual district used as a default for Schools, Teachers, Classes and Students that don't belong to any other districts."
      site_district.save!
      site_school = RitesPortal::School.find_or_create_by_name_and_district_id(APP_CONFIG[:site_school], site_district.id)
      site_school.description = "This is a virtual school used as a default for Teachers, Classes and Students that don't belong to any other schools."
      site_school.save!

      # start with two semesters
      site_school_fall_semester = RitesPortal::Semester.find_or_create_by_name_and_school_id('Fall', site_school.id)
      site_school_spring_semester = RitesPortal::Semester.find_or_create_by_name_and_school_id('Spring', site_school.id)

      # we need at least one grade level, lets start with ninth grade
      attributes = {
        :name => '9',
        :description => '9th grade',
        :school_id => site_school.id
      }
      unless ninth_grade = RitesPortal::GradeLevel.find(:first, :conditions => attributes)
        ninth_grade = RitesPortal::GradeLevel.create!(attributes)
      end
      
      # default course
      site_school_default_course = RitesPortal::Course.find_or_create_by_name_and_school_id('default course', site_school.id)
      site_school_default_course.grade_levels << ninth_grade
      
      # default_school_teacher = teacher_user.portal_teacher.find_or_create_by_school_id(site_school.id)
      unless default_school_teacher = teacher_user.portal_teacher
        default_school_teacher = RitesPortal::Teacher.create!(:user_id => teacher_user.id)
      end
      default_school_teacher.grade_levels << ninth_grade

      # default_school_teacher.courses << site_school_default_course

      # default class
      attributes = {
        :name => 'default class',
        :course_id => site_school_default_course.id,
        :semester_id => site_school_fall_semester.id,
        :teacher_id => default_school_teacher.id,
        :class_word => 'abc12345',
        :description => 'This is a default class created for the default school ... etc'
      }
      unless default_course_class = RitesPortal::Clazz.find(:first, :conditions => attributes)
        default_course_class = RitesPortal::Clazz.create!(attributes)
      end
      default_course_class.status = 'open'
      default_course_class.save
      
      # default offering
      attributes = {
        :clazz_id => default_course_class.id,
        :runnable_id => default_investigation.id,
        :runnable_type => default_investigation.class.name
      }
      unless offering = RitesPortal::Offering.find(:first, :conditions => attributes)
        offering = RitesPortal::Offering.create!(attributes)
      end
      offering.status = 'active'
      offering.save

      # default student
      attributes = {
        :user_id => student_user.id,
        :grade_level_id => ninth_grade.id
      }
      unless default_student = RitesPortal::Student.find(:first, :conditions => attributes)
        default_student = RitesPortal::Student.create!(attributes)
      end
      default_student.student_clazzes.delete_all
      default_student.clazzes << default_course_class
      # default_student = student_user.student || student_user.student.create!
      # 
      puts
    end


    #######################################################################
    #
    # Force Create default users and roles
    # (similar to Create Default users, but without prompting)
    #######################################################################   
    desc "Force Create default users and roles"
    task :force_default_users_roles => :environment do
      admin_role = Role.find_or_create_by_title('admin')
      manager_role = Role.find_or_create_by_title('manager')
      researcher_role = Role.find_or_create_by_title('researcher')
      teacher_role = Role.find_or_create_by_title('teacher')
      member_role = Role.find_or_create_by_title('member')
      student_role = Role.find_or_create_by_title('student')
      guest_role = Role.find_or_create_by_title('guest')

      admin_user = User.create(:login => APP_CONFIG[:admin_login], :email => APP_CONFIG[:admin_email], :password => "password", :password_confirmation => "password", :first_name => APP_CONFIG[:admin_first_name], :last_name => APP_CONFIG[:admin_last_name])
      researcher_user = User.create(:login => 'researcher', :first_name => 'Researcher', :last_name => 'User', :email => 'researcher@concord.org', :password => "password", :password_confirmation => "password")
      member_user = User.create(:login => 'member', :first_name => 'Member', :last_name => 'User', :email => 'member@concord.org', :password => "password", :password_confirmation => "password")
      anonymous_user = User.create(:login => "anonymous", :email => "anonymous@concord.org", :password => "password", :password_confirmation => "password", :first_name => "Anonymous", :last_name => "User")

      [admin_user, researcher_user, member_user].each do |user|
        user.save
        user.register!
        user.activate!
      end
      admin_user.roles << admin_role 
      researcher_user.roles << researcher_role
      member_user.roles << member_role
    end
    
    #######################################################################
    #
    # Force New from scratch
    #
    #######################################################################
    desc "force setup a new rigse instance, with no prompting! Danger!"
    task :force_new_rigse_from_scratch => :environment do
      
      db_config = ActiveRecord::Base.configurations[RAILS_ENV]

      puts <<-HEREDOC
      This task will drop your existing rigse database: #{db_config['database']}, rebuild it from scratch, 
      and install default users.
      HEREDOC
        # save the old data?
        Rake::Task['rigse:setup:development_environment_only'].invoke
        Rake::Task['db:reset'].invoke
        Rake::Task['rigse:setup:force_default_users_roles'].invoke
        Rake::Task['rigse:setup:create_additional_users'].invoke
        Rake::Task['rigse:setup:import_gses_from_file'].invoke
        Rake::Task['db:backup:load_probe_configurations'].invoke
        Rake::Task['rigse:setup:assign_vernier_golink_to_users'].invoke
    end
  end
end