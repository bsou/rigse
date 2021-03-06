require File.expand_path('../../../spec_helper', __FILE__)

def runnable_params(runnable, clazz)
  post_params = {
    :runnable_id => runnable.id,
    :runnable_type => "ExternalActivity",
    :dragged_dom_id => "external_activity_#{runnable.id}",
    :dropped_dom_id => "clazz_offerings",
    :id => clazz.id
  }
end

describe Portal::ClazzesController do
  render_views

  def mock_clazz(stubs={})
    mock_clazz = FactoryBot.create(:portal_clazz, stubs) #mock_model(Portal::Clazz)
    #mock_clazz.stub!(stubs) unless stubs.empty?

    mock_clazz
  end

  def sign_in_symbol(user_sym)
    sign_in instance_variable_get("@#{user_sym}")
  end

  before(:each) do
    @mock_school = FactoryBot.create(:portal_school)

    # set up our user types
    @normal_user = FactoryBot.generate(:anonymous_user)
    @admin_user = FactoryBot.generate(:admin_user)
    @authorized_student =         FactoryBot.create(:portal_student, :user => FactoryBot.create(:confirmed_user, :login => "authorized_student"))
    @authorized_teacher =         FactoryBot.create(:portal_teacher, :user => FactoryBot.create(:confirmed_user, :login => "authorized_teacher"), :schools => [@mock_school])
    @another_authorized_teacher = FactoryBot.create(:portal_teacher, :user => FactoryBot.create(:confirmed_user, :login => "another_authorized_teacher"), :schools => [@mock_school])
    @unauthorized_teacher =       FactoryBot.create(:portal_teacher, :user => FactoryBot.create(:confirmed_user, :login => "unauthorized_teacher"), :schools => [@mock_school])
    # another teacher, to act as an arbitrary third party
    @random_teacher =             FactoryBot.create(:portal_teacher, :user => FactoryBot.create(:confirmed_user, :login => "random_teacher"), :schools => [@mock_school])

    @authorized_teacher_user = @authorized_teacher.user
    @unauthorized_teacher_user = @unauthorized_teacher.user


    @mock_clazz_name = "Random Test Class"
    @mock_course = FactoryBot.create(:portal_course, :name => @mock_clazz_name, :school => @mock_school)
    @mock_clazz = mock_clazz({ :name => @mock_clazz_name, :teachers => [@authorized_teacher, @another_authorized_teacher], :course => @mock_course })

    allow(@controller).to receive(:before_render) {
      allow(response.template).to receive_message_chain(:current_settings, :name).and_return("Test Settings")
    }
    @mock_settings = mock_model(Admin::Settings, :name => "Test Settings")
    allow(@mock_settings).to receive(:enable_grade_levels?).and_return(true)
    allow(@mock_settings).to receive(:allow_default_class).and_return(false)
    allow(@mock_settings).to receive(:use_student_security_questions).and_return(false)
    allow(@mock_settings).to receive(:require_user_consent?).and_return(false)
    allow(@mock_settings).to receive(:default_cohort).and_return(nil)
    allow(Admin::Settings).to receive(:default_settings).and_return(@mock_settings)
  end

  describe "GET show" do
    it "assigns the requested class as @portal_clazz" do
      login_admin
      get :show, :id => @mock_clazz.id
      expect(assigns[:portal_clazz]).to eq(@mock_clazz)
    end

    it "doesn't show class to unauthorized teacheruser" do
      sign_in @unauthorized_teacher_user
      get :show, { :id => @mock_clazz.id }

      expect(response).not_to be_success
      expect(response).to redirect_to("/recent_activity")
    end

    it "saves the position of the left pane submenu item for an authorized teacher" do
      sign_in @authorized_teacher_user

      get :show, { :id => @mock_clazz.id }

      # All users should see the full class details summary
      @authorized_teacher.reload
      expect(@authorized_teacher.left_pane_submenu_item).to eq(Portal::Teacher.LEFT_PANE_ITEM['NONE'])
    end

  end # end describe GET show

  describe "XMLHttpRequest edit" do
    it "doesn't show the details of a class to unauthorized teachers" do
      sign_in @unauthorized_teacher_user
      teachers = [@authorized_teacher, @random_teacher]
      @mock_clazz.teachers = teachers

      xml_http_html_request :post, :edit, :id => @mock_clazz.id

      expect(response).not_to be_success
    end

    it "should not allow me to modify the requested class's school" do
      login_admin
      xml_http_request :post, :edit, :id => @mock_clazz.id

      assert_select("select[name=?]", "#{@mock_clazz.class.table_name.singularize}[school]", false)
    end

    def can_edit(teacher)
      assert_select("table.teachers_listing") do
        assert_select("input#clazz_teacher_#{teacher.id}:not([disabled='disabled'])")
      end
    end

    def cant_edit(teacher)
      assert_select("table.teachers_listing") do
        assert_select("input#clazz_teacher_#{teacher.id}[disabled='disabled']")
      end
    end

    describe "conditions for a user trying to remove a teacher from a class" do

      # TODO: Verify we are fine with preventing the current user from removing themselves.
      # it "this teacher is the last teacher assigned to this class" do
      #   # @mock_clazz should only have one teacher, but let's make sure
      #   teachers = [@authorized_teacher]
      #   @mock_clazz.teachers = teachers

      #   xml_http_html_request :post, :edit, :id => @mock_clazz.id

      #   # There should be only one teacher listed, and it should not be enabled
      #   assert_select("div#teachers_listing") do
      #     assert_select("tr#portal__teacher_#{teachers.first.id}") do
      #       assert_select("img[src*='delete_grey.png'][title=?]", Portal::Clazz::ERROR_REMOVE_TEACHER_LAST_TEACHER)
      #     end
      #   end
      # end


    end

    [:admin_user, :authorized_teacher_user, :unauthorized_teacher_user].each do |user|
      if user == :unauthorized_teacher_user
        does_this = "does not populate the list of available teachers for ADD functionality if current user is unauthorized"
      else
        does_this = "populates the list of available teachers for ADD functionality if current user is a #{user}"
      end
      it does_this do
        sign_in_symbol user

        xml_http_html_request :post, :edit, :id => @mock_clazz.id

        if user == :unauthorized_teacher_user
          assert_select("select#teacher_id_selector", false,
            "Unauthorized users should not see the 'add teacher' link")
        else
          assert_select("select#teacher_id_selector")
        end
      end
    end
  end

  describe "POST add_teacher" do
    [:admin_user, :authorized_teacher_user, :unauthorized_teacher_user].each do |user|
      it "will add the selected teacher to the given class if the current user is authorized" do
        # @id
        # @teacher_id
        sign_in_symbol user

        post :add_teacher, { :id => @mock_clazz.id, :teacher_id => @unauthorized_teacher.id }

        @mock_clazz.reload

        if user == :unauthorized_teacher_user
          # Unauthorized users cannot add teachers, and will receive an error message
          assert !@mock_clazz.teachers.include?(@unauthorized_teacher)
          assert @response.body.include?(Portal::Clazz::ERROR_UNAUTHORIZED)
        else
          # Authorized users can add teachers
          assert @mock_clazz.teachers.include?(@unauthorized_teacher)
        end
      end
    end
  end

  describe "DELETE remove_teacher" do
    [:admin_user, :authorized_teacher_user, :unauthorized_teacher_user].each do |user|
      it "will remove the selected teacher from the given class if the current user is authorized" do
        # @id
        # @teacher_id
        sign_in_symbol user

        teachers = [@authorized_teacher, @random_teacher] # Any teachers except for @unauthorized_teacher will work here
        @mock_clazz.teachers = teachers

        delete :remove_teacher, { :id => @mock_clazz.id, :teacher_id => teachers.first.id }

        @mock_clazz.reload

        if user == :unauthorized_teacher_user
          # Unauthorized users cannot remove teachers, and will receive an error message
          assert @mock_clazz.teachers.include?(teachers.first)
          assert @response.body.include?(Portal::Clazz::ERROR_UNAUTHORIZED)
        else
          # Authorized users can remove teachers
          assert !@mock_clazz.teachers.include?(teachers.first)
        end
      end
    end

    it "will not let me remove the last teacher from the given class" do
      login_admin
      #remove one teacher
      delete :remove_teacher, { :id => @mock_clazz.id, :teacher_id => @another_authorized_teacher.id }

      #remove last teacher
      delete :remove_teacher, { :id => @mock_clazz.id, :teacher_id => @authorized_teacher.id }

      @mock_clazz.reload

      assert @mock_clazz.teachers.include?(@authorized_teacher)
      assert @response.body.include?(Portal::Clazz::ERROR_REMOVE_TEACHER_LAST_TEACHER)
    end

    it "will disable the remaining delete button if there is only one remaining teacher after this operation" do
      login_admin
      teachers = [@authorized_teacher, @random_teacher]
      @mock_clazz.teachers = teachers

      delete :remove_teacher, { :id => @mock_clazz.id, :teacher_id => @authorized_teacher.id }

      assert_select("tr#portal__teacher_#{@random_teacher.id}") do
        assert_select("img[src*='delete_grey.png'][title=?]", Portal::Clazz::ERROR_REMOVE_TEACHER_LAST_TEACHER)
      end
    end

    # REMOVED -- we now redraw the entire teacher listing each time a teacher is removed, in case the delete permissions change between operations.
    # it "will remove a teacher listing with JavaScript if there is more than one remaining teacher after this operation" do
    #   teachers = [@authorized_teacher, @unauthorized_teacher, @random_teacher]
    #   @mock_clazz.teachers = teachers
    #
    #   delete :remove_teacher, { :id => @mock_clazz.id, :teacher_id => @authorized_teacher.id }
    #
    #   without_tag("tr") # All teacher listings are in table rows; we shouldn't be actually rendering any HTML content here.
    # end

    it "will re-render the teacher listing when a teacher is removed" do
      login_admin
      teachers = [@authorized_teacher, @unauthorized_teacher, @random_teacher]
      @mock_clazz.teachers = teachers

      delete :remove_teacher, { :id => @mock_clazz.id, :teacher_id => @authorized_teacher.id }

      assert_select("tr#portal__teacher_#{@unauthorized_teacher.id}")
      assert_select("tr#portal__teacher_#{@random_teacher.id}")
      assert_select("tr#portal__teacher_#{@authorized_teacher.id}", false)
    end

    [:authorized_teacher_user, :unauthorized_teacher_user].each do |user|
      it "will redirect the user to their home page if they remove themselves from a class" do
        sign_in_symbol user

        teachers = [@authorized_teacher, @unauthorized_teacher]
        @mock_clazz.teachers = teachers

        delete :remove_teacher, { :id => @mock_clazz.id, :teacher_id => @authorized_teacher.id }

        if user == :authorized_teacher_user
          expect(@response.body).to include(home_url)
        else
          expect(@response.body).not_to include(home_url)
        end
      end
    end
  end

  describe "GET new" do
    it "should show a list of the current teacher's schools to which to assign this class" do
      sign_in @authorized_teacher_user

      get :new

      assert_select("select[name=?]", "#{@mock_clazz.class.table_name.singularize}[school]") do
        @authorized_teacher_user.portal_teacher.schools.each do |school|
          assert_select("option[value='#{school.id}']", :text => school.name)
        end
      end
    end

    it "should show a check box for each possible site grade level" do
      sign_in @authorized_teacher_user

      get :new

      APP_CONFIG[:active_grades].each do |name|
        assert_select("input[type='checkbox'][name=?]", "portal_clazz[grade_levels][#{name}]")
      end
    end

    [:admin_user, :authorized_teacher_user].each do |user|
      it "should populate the schools list with the settings default school if the current user does not belong to any schools" do
        sign_in_symbol user

        get :new

        assert_select("select[name=?]", "#{@mock_clazz.class.table_name.singularize}[school]") do
          assert_select("option", :count => 1)
          assert_select("option", :text => APP_CONFIG[:site_school])
        end
      end
    end

    # REMOVED -- teachers must create the class before being able to add teachers.
    # it "populates the list of available teachers for ADD functionality" do
    #   login_as :authorized_teacher_user
    #
    #   1.upto 10 do |i|
    #     teacher = FactoryBot.create(:portal_teacher, :user => FactoryBot.create(:user, :login => "teacher#{i}"))
    #     @logged_in_user.portal_teacher.school.portal_teachers << teacher
    #   end
    #
    #   get :new
    #
    #   assert_select("select#teacher_id_selector[name=teacher_id]") do |elem|
    #     without_tag("option[value=?]", @logged_in_user.portal_teacher.id) # cannot add teachers who are already assigned to this class
    #
    #     @logged_in_user.portal_teacher.school.portal_teachers.reject { |t| t.id == @logged_in_user.portal_teacher.id }.each do |t|
    #       assert_select("option[value=?]", t.id)
    #     end
    #   end
    # end
  end # end describe "GET new"

  describe "POST create" do
    before(:each) do
      # Make sure we have the grade levels we want
      0.upto(12) do |num|
        grade = Portal::Grade.where(name: num.to_s).first_or_create
        grade.active = true
        grade.save!
      end

      @post_params = {
        :portal_clazz => {
          :name => "New Test Class",
          :class_word => "1020304050",
          :school => @mock_school.id,
          :description => "Test!",
          :teacher_id => @authorized_teacher.id,
          :grade_levels => {
            :"6" => "1",
            :"7" => "1",
            :"9" => "1"
          }
        }
      }
    end

    it "should create a new class, assigned to the correct teacher, in the correct school" do
      sign_in @authorized_teacher_user

      post :create, @post_params

      @mock_school.reload
      @authorized_teacher.reload

      @new_clazz = Portal::Clazz.find_by_class_word(@post_params[:portal_clazz][:class_word])

      assert @new_clazz
      expect(@new_clazz.school).to eq(@mock_school)
      expect(@authorized_teacher.clazzes).to include(@new_clazz)
      expect(@mock_school.clazzes).to include(@new_clazz)
    end

    it "should attach this class to the appropriate course in the specified school, if one exists" do
      course = FactoryBot.create(:portal_course, :name => @post_params[:portal_clazz][:name], :school => @mock_school)
      assert course
      expect(course.clazzes.size).to eq(0)

      sign_in @authorized_teacher_user

      post :create, @post_params

      course.reload

      @new_clazz = Portal::Clazz.find_by_class_word(@post_params[:portal_clazz][:class_word])

      expect(@new_clazz.course).to eq(course)
      expect(course.clazzes.size).to eq(1)
      expect(course.clazzes).to include(@new_clazz)
      expect(course.school.clazzes).to include(@new_clazz)
    end

    it "should create a new course in the specified school if this class has a unique name" do
      expect(Portal::Course.find_by_name(@post_params[:portal_clazz][:name])).to be_nil

      sign_in @authorized_teacher_user

      post :create, @post_params

      @mock_school.reload
      course = Portal::Course.find_by_name(@post_params[:portal_clazz][:name])

      assert course
      expect(@mock_school.courses).to include(course)
    end

    it "should create exactly one teacher object for the current user if the current user does not already have one" do
      @random_user = FactoryBot.create(:confirmed_user, :login => "random_user")
      sign_in @random_user

      expect(@random_user.portal_teacher).to be_nil
      current_count = Portal::Teacher.count

      @post_params[:portal_clazz][:teacher_id] = nil

      post :create, @post_params

      @random_user.reload

      expect(@random_user.portal_teacher).not_to be_nil
      expect(Portal::Teacher.count).to eq(current_count + 1)
    end

    it "should not let me create a class with no school" do
      sign_in @authorized_teacher_user

      current_count = Portal::Clazz.count

      @post_params[:portal_clazz][:school] = nil

      post :create, @post_params

      assert flash[:error]
      expect(Portal::Clazz.count).to eq(current_count)
    end

    it "should assign the specified grade levels to the new class" do
      sign_in @authorized_teacher_user

      post :create, @post_params

      @new_clazz = Portal::Clazz.find_by_class_word(@post_params[:portal_clazz][:class_word])

      @post_params[:portal_clazz][:grade_levels].each do |name, v|
        grade = Portal::Grade.find_by_name(name.to_s)
        expect(@new_clazz.grades).to include(grade)
      end
    end

    it "should not let me create a class with no grade levels when grade levels are enabled" do
      sign_in @authorized_teacher_user

      current_count = Portal::Clazz.count

      @post_params[:portal_clazz][:grade_levels] = nil

      post :create, @post_params

      assert flash[:error]
      expect(Portal::Clazz.count).to equal(current_count)
    end

    it "should let me create a class with no grade levels when grade levels are disabled" do
      allow(@mock_settings).to receive(:enable_grade_levels?).and_return(false)
      @post_params[:portal_clazz].delete(:grade_levels)

      sign_in @authorized_teacher_user

      current_count = Portal::Clazz.count

      post :create, @post_params

      expect(Portal::Clazz.count).to equal(current_count + 1)
    end
  end

  describe "PUT update" do
    before(:each) do
      # Make sure we have the grade levels we want
      0.upto(12) do |num|
        grade = Portal::Grade.where(name: num.to_s).first_or_create
        grade.active = true
        grade.save!
      end

      @post_params = {
        :id => @mock_clazz.id,
        :portal_clazz => {
          :name => "New Test Class",
          :class_word => "1020304050",
          :description => "Test!",
          :teacher_id => @authorized_teacher.id,
          :grade_levels => {
            :"6" => "1",
            :"7" => "1",
            :"9" => "1"
          }
        }
      }
    end

    it "should not let me update a class with no grade levels when grade levels are enabled" do
      sign_in @authorized_teacher_user

      @post_params[:portal_clazz][:grade_levels] = nil

      put :update, @post_params

      assert flash[:error]
    end

    it "should let me update a class with no grade levels when grade levels are disabled" do
      allow(@mock_settings).to receive(:enable_grade_levels?).and_return(false)
      @post_params[:portal_clazz].delete(:grade_levels)

      sign_in @authorized_teacher_user

      put :update, @post_params

      expect(Portal::Clazz.find(@mock_clazz.id).name).to eq('New Test Class')
    end
  end

  describe "POST add_offering" do
    it "should run without error" do
      login_admin
      external_activity = FactoryBot.create(:external_activity)
      post_params = runnable_params(external_activity, @mock_clazz)
      post :add_offering, post_params
    end
  end


  describe "Post edit class information" do
    before(:each) do
      external_activity = FactoryBot.create(:external_activity)
      post_params = runnable_params(external_activity, @mock_clazz)
      post :add_offering, post_params
      offers = Array.new
      @mock_clazz.offerings.each do|offering|
        offers << offering.id.to_s
      end

      @post_params = {
          :id => @mock_clazz.id,
          :portal_clazz => {
            :name => 'electrical engineering circuits and system',
            :class_word => 'EECS',
            :description => 'Test!',
            :teacher_id => @authorized_teacher.id.to_s,
            :grade_levels => {
              :"6" => "1",
              :"7" => "1",
              :"9" => "1"
            }
          },
          :clazz_investigations_ids => offers,
          :clazz_active_investigations => offers,
          :clazz_teacher_ids => (@authorized_teacher.id.to_s + "," + @another_authorized_teacher.id.to_s)
        }

    end




    it "should not save the edited class info if the class name is blank" do
      login_admin
      @post_params[:portal_clazz][:name] = ''
      post :update, @post_params
      @portal_clazz = Portal::Clazz.find_by_id(@post_params[:id])
      expect(@portal_clazz.name).not_to eq(''), 'Class saved with no name.'
    end

    it "should not save the edited class info if the class word is blank" do
      login_admin
      @post_params[:portal_clazz][:class_word] = ''
      post :update, @post_params
      @portal_clazz = Portal::Clazz.find_by_id(@post_params[:id])
      expect(@portal_clazz.class_word).not_to eq(''), 'Class saved with blank class word.'
    end
  end

  describe "Post add a new student to a class" do

    it "should add a new student to the class" do
      login_admin
      post_params = {
        :id => @mock_clazz.id.to_s,
        :student_id => @authorized_student.id.to_s
      }
      post :add_student, post_params
      newStudentInClazz = Portal::StudentClazz.find_by_clazz_id_and_student_id(@mock_clazz.id, @authorized_student.id)
      expect(newStudentInClazz).not_to be_nil
    end
  end


  describe "Put teacher Manage class" do
    before(:each) do
      @mock_teacher_clazz = Portal::TeacherClazz.find_by_clazz_id_and_teacher_id(@mock_clazz.id, @authorized_teacher.id)

      mock_clazz_name = "Mock Class Physics"
      @mock_clazz_phy = mock_clazz({ :name => mock_clazz_name, :teachers => [@authorized_teacher], :course => @mock_course })
      @authorized_teacher.add_clazz(@mock_clazz_phy)
      @authorized_teacher.save!
      @mock_teacher_clazz_phy = Portal::TeacherClazz.find_by_clazz_id_and_teacher_id(@mock_clazz_phy.id, @authorized_teacher.id)

      mock_clazz_name = "Mock Class Chemistry"
      @mock_clazz_chem = mock_clazz({ :name => mock_clazz_name, :teachers => [@authorized_teacher], :course => @mock_course })
      @authorized_teacher.add_clazz(@mock_clazz_chem)
      @authorized_teacher.save!
      @mock_teacher_clazz_chem = Portal::TeacherClazz.find_by_clazz_id_and_teacher_id(@mock_clazz_chem.id, @authorized_teacher.id)

      mock_clazz_name = "Mock Class Biology"
      @mock_clazz_bio = mock_clazz({ :name => mock_clazz_name, :teachers => [@authorized_teacher], :course => @mock_course })
      @authorized_teacher.add_clazz(@mock_clazz_bio)
      @authorized_teacher.save!
      @mock_teacher_clazz_bio = Portal::TeacherClazz.find_by_clazz_id_and_teacher_id(@mock_clazz_bio.id, @authorized_teacher.id)

      mock_clazz_name = "Mock Class Mathematics"
      @mock_clazz_math = mock_clazz({ :name => mock_clazz_name, :teachers => [@authorized_teacher], :course => @mock_course })
      @authorized_teacher.add_clazz(@mock_clazz_math)
      @authorized_teacher.save!
      @mock_teacher_clazz_math = Portal::TeacherClazz.find_by_clazz_id_and_teacher_id(@mock_clazz_math.id, @authorized_teacher.id)

      @authorized_teacher.reload

    end

    it "should should save all the activated and deactivated classes and in the right order" do
      sign_in @authorized_teacher_user
      @post_params = {
        'teacher_clazz'  => Array[@mock_teacher_clazz.id , @mock_teacher_clazz_phy.id , @mock_teacher_clazz_bio.id , @mock_teacher_clazz_math.id ],
        'teacher_clazz_position'  => Array[@mock_teacher_clazz_math.id , @mock_teacher_clazz_phy.id , @mock_teacher_clazz_chem.id, @mock_teacher_clazz_bio.id ,@mock_teacher_clazz.id ]
      }
      put :manage_classes, @post_params

      teacher_clazz = Portal::TeacherClazz.find_by_clazz_id_and_teacher_id(@mock_clazz.id, @authorized_teacher.id)
      expect(teacher_clazz).not_to be_nil
      assert(teacher_clazz.active)
      expect(teacher_clazz.position).to eq(5)

      teacher_clazz = Portal::TeacherClazz.find_by_clazz_id_and_teacher_id(@mock_clazz_phy.id, @authorized_teacher.id)
      expect(teacher_clazz).not_to be_nil
      assert(teacher_clazz.active)
      expect(teacher_clazz.position).to eq(2)

      teacher_clazz = Portal::TeacherClazz.find_by_clazz_id_and_teacher_id(@mock_clazz_chem.id, @authorized_teacher.id)
      expect(teacher_clazz).not_to be_nil
      assert(teacher_clazz.active == false)
      expect(teacher_clazz.position).to eq(3)

      teacher_clazz = Portal::TeacherClazz.find_by_clazz_id_and_teacher_id(@mock_clazz_bio.id, @authorized_teacher.id)
      expect(teacher_clazz).not_to be_nil
      assert(teacher_clazz.active)
      expect(teacher_clazz.position).to eq(4)

      teacher_clazz = Portal::TeacherClazz.find_by_clazz_id_and_teacher_id(@mock_clazz_math.id, @authorized_teacher.id)
      expect(teacher_clazz).not_to be_nil
      assert(teacher_clazz.active)
      expect(teacher_clazz.position).to eq(1)

    end
  end

  describe "Post teacher Creates copy of a class" do
    before(:each) do

      @student_clazz = Portal::StudentClazz.new
      @student_clazz.clazz_id = @mock_clazz.id
      @student_clazz.student_id = @authorized_student.id
      @student_clazz.save!

      @investigation = FactoryBot.create(:investigation)
      @investigation.name = 'Fluid Mechanics'
      @investigation.save!

      @offering = Portal::Offering.new
      @offering.runnable_id = @investigation.id
      @offering.clazz_id = @mock_clazz.id
      @offering.runnable_type = 'Investigation'
      @offering.save!
      sign_in @authorized_teacher_user

      @post_params = {
        :id => @mock_clazz.id,
        :clazz_name  => 'Concept of physics',
        :clazz_desc  => 'Concept of physics',
        :clazz_word => 'Phy123456'
      }
    end

    it "should create a new class that's a copy of the original class with investigations and teachers but no students" do
      xhr :post, :copy_class, @post_params

      @copy_clazz = Portal::Clazz.find_by_name('Concept of physics')
      expect(@copy_clazz).not_to be_nil

      expect(@copy_clazz.teachers.length).to eq(@mock_clazz.teachers.length)
      @mock_clazz.teachers.each do |teacher|
        expect(@copy_clazz.teachers.find_by_id(teacher.id)).not_to be_nil
      end

      expect(@copy_clazz.offerings.length).to eq(@mock_clazz.offerings.length)
      @mock_clazz.offerings.each do |offering|
        expect(@copy_clazz.offerings.find_by_runnable_id(offering.runnable_id)).not_to be_nil
      end

      expect(@copy_clazz.students.length).to eq(0)

    end
  end


  # GET edit
  describe "GET edit" do

    it "saves the position of the left pane submenu item for an authorized teacher" do
      sign_in @authorized_teacher_user

      get :edit, { :id => @mock_clazz.id }

      # All users should see the full class details summary
      @authorized_teacher.reload
      expect(@authorized_teacher.left_pane_submenu_item).to eq(Portal::Teacher.LEFT_PANE_ITEM['CLASS_SETUP'])
    end

  end

  # GET materials
  describe "GET materials" do

    it "saves the position of the left pane submenu item for an authorized teacher" do
      sign_in @authorized_teacher_user

      get :materials, { :id => @mock_clazz.id }

      # All users should see the full class details summary
      @authorized_teacher.reload
      expect(@authorized_teacher.left_pane_submenu_item).to eq(Portal::Teacher.LEFT_PANE_ITEM['MATERIALS'])
    end

  end

  # GET roster
  describe "GET roster" do

    it "saves the position of the left pane submenu item for an authorized teacher" do
      sign_in @authorized_teacher_user

      get :roster, { :id => @mock_clazz.id }

      # All users should see the full class details summary
      @authorized_teacher.reload
      expect(@authorized_teacher.left_pane_submenu_item).to eq(Portal::Teacher.LEFT_PANE_ITEM['STUDENT_ROSTER'])
    end

  end


  describe "Post teacher sorts class offerings on class summary page" do
    before(:each) do
      @physics_offering = FactoryBot.create(:portal_offering)
      @chemistry_offering = FactoryBot.create(:portal_offering)
      @biology_offering = FactoryBot.create(:portal_offering)
      @mathematics_offering = FactoryBot.create(:portal_offering)
      @params = {
        :clazz_offerings => [@physics_offering.id, @chemistry_offering.id, @biology_offering.id , @mathematics_offering.id]
      }
      sign_in @authorized_teacher_user
    end
    it "should store position of all the offerings after teacher sorts offerings" do

      # Save initial offering positions
      xhr :post, :sort_offerings, @params
      offerings = Portal::Offering.where(:id => @params[:clazz_offerings])
      offerings.each do |offering|
        expect(offering.position ).to eq(@params[:clazz_offerings].index(offering.id) + 1)
      end

      # Update offering positions and verify they have been updated
      @params[:clazz_offerings] = [@mathematics_offering.id, @biology_offering.id, @chemistry_offering.id, @physics_offering.id]
      xhr :post, :sort_offerings, @params
      offerings = Portal::Offering.where(:id => @params[:clazz_offerings])
      offerings.each do |offering|
        expect(offering.position ).to eq(@params[:clazz_offerings].index(offering.id) + 1)
      end
    end
  end

  describe "GET fullstatus" do
    before(:each) do
      @params = {
        :id => @mock_clazz.id
      }
    end
    it "should not allow access for anonymous user" do
      sign_out :user
      get :fullstatus, @params
      expect(response).not_to be_success
    end
    it "should retrieve the class when user is not anonymous user" do
      sign_in @authorized_teacher_user
      get :fullstatus, @params
      expect(assigns[:portal_clazz]).to eq(@mock_clazz)
      expect(response).to be_success
      expect(response).to render_template("fullstatus")
    end
  end

  describe "Post add new student popup" do
    it "should show a popup to add a new student" do
      #creating real objects for settings and making it current settings
      #A related example http://stackoverflow.com/questions/5223247/rspec-error-mock-employee-1-received-unexpected-messageto-ary-withno-args
      @mock_settings = Admin::Settings.new
      @mock_settings.home_page_content = nil
      @mock_settings.use_student_security_questions = true
      @mock_settings.use_bitmap_snapshots = true
      @mock_settings.allow_adhoc_schools = true
      @mock_settings.require_user_consent = true
      @mock_settings.allow_default_class = true
      @mock_settings.jnlp_cdn_hostname = ''
      @mock_settings.save!
      allow(Admin::Settings).to receive(:default_settings).and_return(@mock_settings)

      sign_in @authorized_teacher_user

      @params = {
        :id => @mock_clazz.id
      }
      xhr :post, :add_new_student_popup, @params
      expect(response).to be_success
      expect(response).to render_template(:partial => "portal/students/_form")
    end
  end


  # TODO: auto-generated
  describe '#current_clazz' do
    it 'GET current_clazz' do
      get :current_clazz, {}, {}

      expect(response).to have_http_status(:not_found)
    end
  end

end
