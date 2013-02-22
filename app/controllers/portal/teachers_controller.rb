class Portal::TeachersController < ApplicationController
  include RestrictedPortalController
  before_filter :teacher_admin_or_manager, :except=> [:new, :create]
  public

  def teacher_admin_or_manager
    if current_visitor.has_role?('admin') ||
       current_visitor.has_role?('manager') ||
       (current_visitor.portal_teacher && current_visitor.portal_teacher.id.to_s == params[:id])
       # this user is authorized
       true
    else
      flash[:notice] = "Please log in as an administrator or manager"
      redirect_to(:home)
    end
  end

  # GET /portal_teachers
  # GET /portal_teachers.xml
  def index
    @portal_teachers = Portal::Teacher.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @portal_teachers }
    end
  end

  # GET /portal_teachers/1
  # GET /portal_teachers/1.xml
  def show
    @portal_teacher = Portal::Teacher.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @portal_teacher }
    end
  end

  # GET /portal_teachers/view
  # GET /portal_teachers/new.xml
  def new
    @portal_teacher = Portal::Teacher.new
    @school_selector = Portal::SchoolSelector.new(params)
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @portal_teacher }
    end
  end

  # GET /portal_teachers/1/edit
  def edit
    @portal_teacher = Portal::Teacher.find(params[:id])
    @user = @portal_teacher.user
    @school_selector = Portal::SchoolSelector.new(params)
  end

  # POST /portal_teachers
  # POST /portal_teachers.xml
  # TODO: move some of this into the teachers model.
  def create
    
    # TODO: Teachers DO NOT HAVE grades or Domains.
    @portal_grade = nil
    if params[:grade]
      @portal_grade = Portal::Grade.find(params[:grade][:id])
    end
    @domain = nil
    if params[:domain]
      @domain = RiGse::Domain.find(params[:domain][:id])
    end

    @user = User.new(params[:user])
    @school_selector = Portal::SchoolSelector.new(params)

    if (@user.valid?)
      # TODO: save backing DB objects
      # @school_selector.save
    end
    @portal_teacher = Portal::Teacher.new do |t|
      t.user = @user
      t.domain = @domain
      t.schools << @school_selector.school if @school_selector.valid?
      t.grades << @portal_grade if !@portal_grade.nil?
    end
    if @school_selector.valid? && @user.register! && @portal_teacher.save
      # will redirect:
      return successful_creation(@user)
    end

    # Luckily, ActiveRecord errors allow you to attach errors to arbitrary, non-existant attributes
    # will redirect:
    @user.errors.add(:you, "must select a school") unless @school_selector.valid?
    failed_creation
  end

  # PUT /portal_teachers/1
  # PUT /portal_teachers/1.xml
  def update
    @portal_teacher = Portal::Teacher.find(params[:id])

    respond_to do |format|
      if @portal_teacher.update_attributes(params[:teacher])
        flash[:notice] = 'Portal::Teacher was successfully updated.'
        format.html { redirect_to(@portal_teacher) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @portal_teacher.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /portal_teachers/1
  # DELETE /portal_teachers/1.xml
  def destroy
    @portal_teacher = Portal::Teacher.find(params[:id])
    @portal_teacher.destroy

    respond_to do |format|
      format.html { redirect_to(portal_teachers_url) }
      format.xml  { head :ok }
    end
  end
  
  def successful_creation(user)
    # Render the UsersController#thanks page instead of showing a flash message.
    render :template => 'users/thanks'
  end
  
  def failed_creation(message = 'Sorry, there was an error creating your account')
    # force the current_visitor to anonymous, because we have not successfully created an account yet.
    # edge case, which we might need a more integrated solution for??
    self.current_visitor = User.anonymous
    flash.now[:error] = message
    render :action => :new
  end
  
end
