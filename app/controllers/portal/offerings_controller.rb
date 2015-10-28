class Portal::OfferingsController < ApplicationController

  include RestrictedPortalController
  include Portal::LearnerJnlpRenderer

  # PUNDIT_CHECK_FILTERS
  before_filter :teacher_admin_or_config, :only => [:report, :open_response_report, :multiple_choice_report, :separated_report, :report_embeddable_filter,:activity_report]
  before_filter :student_teacher_admin_or_config, :only => [:answers]
  before_filter :student_teacher_or_admin, :only => [:show]

  def current_clazz
    Portal::Offering.find(params[:id]).clazz
  end

  public

  # GET /portal_offerings
  # GET /portal_offerings.xml
  def index
    authorize Portal::Offering
    @portal_offerings = policy_scope(Portal::Offering)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @portal_offerings }
    end
  end

  # GET /portal_offerings/1
  # GET /portal_offerings/1.xml
  def show
    @offering = Portal::Offering.find(params[:id])
    authorize @offering

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @offering }

      format.run_html   {
        @learner = setup_portal_student
        render :show, :layout => "layouts/run"
      }
      format.run_sparks_html   {
        if learner = setup_portal_student
          session[:put_path] = saveable_sparks_measuring_resistance_url(:format => :json)
        else
          session[:put_path] = nil
        end
        render 'pages/show', :layout => "layouts/run"
      }

      format.run_resource_html   {
         if learner = setup_portal_student
           cookies[:save_path] = @offering.runnable.save_path
           cookies[:learner_id] = learner.id
           cookies[:student_name] = "#{current_visitor.first_name} #{current_visitor.last_name}"
           cookies[:activity_name] = @offering.runnable.name
           cookies[:class_id] = learner.offering.clazz.id
           cookies[:student_id] = learner.student.id
           cookies[:runnable_id] = @offering.runnable.id
           # session[:put_path] = saveable_sparks_measuring_resistance_url(:format => :json)
         else
           # session[:put_path] = nil
         end
         external_activity = @offering.runnable
         if external_activity.launch_url
           uri = URI.parse(external_activity.launch_url)
           uri.query = {
             :domain => root_url,
             :externalId => learner.id,
             :returnUrl => external_activity_return_url(learner.id),
             :logging => @offering.clazz.logging || @offering.runnable.logging,
             :domain_uid => current_visitor.id
           }.to_query
           redirect_to(uri.to_s)
         else
           redirect_to(@offering.runnable.url(learner))
         end
       }

      format.jnlp {
        # check if the user is a student in this offering's class
        if learner = setup_portal_student
          render_learner_jnlp learner
        else
          # The current_visitor is a teacher (or another user acting like a teacher)
          render :partial => 'shared/installer', :locals => { :runnable => @offering.runnable, :teacher_mode => true }
        end
      }
    end
  end

  # GET /portal_offerings/new
  # GET /portal_offerings/new.xml
  def new
    authorize Portal::Offering
    @offering = Portal::Offering.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @offering }
    end
  end

  # GET /portal_offerings/1/edit
  def edit
    @offering = Portal::Offering.find(params[:id])
    authorize @offering
  end

  # POST /portal_offerings
  # POST /portal_offerings.xml
  def create
    authorize Portal::Offering
    @offering = Portal::Offering.new(params[:offering])

    respond_to do |format|
      if @offering.save
        flash[:notice] = 'Portal::Offering was successfully created.'
        format.html { redirect_to(@offering) }
        format.xml  { render :xml => @offering, :status => :created, :location => @offering }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @offering.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /portal_offerings/1
  # PUT /portal_offerings/1.xml
  def update
    @offering = Portal::Offering.find(params[:id])
    authorize @offering

    respond_to do |format|
      if @offering.update_attributes(params[:offering])
        flash[:notice] = 'Portal::Offering was successfully updated.'
        format.html { redirect_to(@offering) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @offering.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /portal_offerings/1
  # DELETE /portal_offerings/1.xml
  def destroy
    @offering = Portal::Offering.find(params[:id])
    authorize @offering
    @offering.destroy

    respond_to do |format|
      format.html { redirect_to(portal_offerings_url) }
      format.xml  { head :ok }
    end
  end

  def activate
    @offering = Portal::Offering.find(params[:id])
    authorize @offering, :update_edit_or_destroy?
    @offering.activate!
    redirect_to :back
  end

  def deactivate
    @offering = Portal::Offering.find(params[:id])
    authorize @offering, :update_edit_or_destroy?
    @offering.deactivate!
    redirect_to :back
  end

  def report
    @offering = Portal::Offering.find(params[:id])
    # PUNDIT_REVIEW_AUTHORIZE
    authorize @offering, :show
    @activity_report_id = nil
    @report_embeddable_filter = []
    unless @offering.report_embeddable_filter.nil? || @offering.report_embeddable_filter.embeddables.nil?
      @report_embeddable_filter = @offering.report_embeddable_filter.embeddables
    end
    unless params[:activity_id].nil?
      activity = ::Activity.find(params[:activity_id].to_i)
      @activity_report_id = params[:activity_id].to_i
      unless activity.nil?
        activity_embeddables = activity.page_elements.map{|pe|pe.embeddable}
        if @offering.report_embeddable_filter.ignore
          @offering.report_embeddable_filter.embeddables = activity_embeddables
        else
           filtered_embeddables = @offering.report_embeddable_filter.embeddables & activity_embeddables
           filtered_embeddables = (filtered_embeddables.length == 0)? activity_embeddables : filtered_embeddables
           @offering.report_embeddable_filter.embeddables = filtered_embeddables
        end
        @offering.report_embeddable_filter.ignore = false
      end
    end

    respond_to do |format|
      format.html {
        reportUtil = Report::Util.reload(@offering)  # force a reload of this offering
        @learners = reportUtil.learners
        @page_elements = reportUtil.page_elements

        render :layout => 'report' # report.html.haml
      }

      format.run_resource_html   {
        @learners = @offering.clazz.students.map do |l|
          "name: '#{l.name}', id: #{l.id}"
        end
        cookies[:activity_name] = @offering.runnable.url
        cookies[:class] = @offering.clazz.id
        cookies[:class_students] = "[{" + @learners.join("},{") + "}]" # formatted for JSON parsing

        redirect_to(@offering.runnable.report_url, 'popup' => true)
       }
    end


  end

  def multiple_choice_report
    @offering = Portal::Offering.find(params[:id], :include => :learners)
    # PUNDIT_REVIEW_AUTHORIZE
    authorize @offering, :show
    @offering_report = Report::Offering::Investigation.new(@offering)

    respond_to do |format|
      format.html { render :layout => 'report' }# multiple_choice_report.html.haml
    end
  end

  def open_response_report
    @offering = Portal::Offering.find(params[:id], :include => :learners)
    # PUNDIT_REVIEW_AUTHORIZE
    authorize @offering, :show
    @offering_report = Report::Offering::Investigation.new(@offering)

    respond_to do |format|
      format.html { render :layout => 'report' }# open_response_report.html.haml
    end
  end

  def separated_report
    @offering = Portal::Offering.find(params[:id])
    # PUNDIT_REVIEW_AUTHORIZE
    authorize @offering, :show
    reportUtil = Report::Util.reload(@offering)  # force a reload of this offering
    @learners = reportUtil.learners

    @page_elements = reportUtil.page_elements

    respond_to do |format|
      format.html { render :layout => 'report' }# report.html.haml
    end
  end

  def report_embeddable_filter
    @offering = Portal::Offering.find(params[:id])
    # PUNDIT_REVIEW_AUTHORIZE
    authorize @offering, :show
    @report_embeddable_filter = @offering.report_embeddable_filter
    @filtered = true
    activity_report_id = params[:activity_id]
    if params[:commit] == "Show all"
      @report_embeddable_filter.ignore = true
    else
      @report_embeddable_filter.ignore = false
    end
    if params[:filter]
      embeddables = params[:filter].collect{|type, ids|
        logger.info "processing #{type}: #{ids.inspect}"
        klass = type.constantize
        ids.collect{|id|
          klass.find(id.to_i)
        }
      }.flatten.compact.uniq
    else
      embeddables = []
    end

    if activity_report_id
      activity = ::Activity.find(activity_report_id.to_i)
      activity_embeddables = activity.page_elements.map{|pe|pe.embeddable}
      @report_embeddable_filter.embeddables = (@report_embeddable_filter.embeddables - activity_embeddables) | embeddables
    else
      @report_embeddable_filter.embeddables = embeddables
    end

    respond_to do |format|
      if @report_embeddable_filter.save
          flash[:notice] = 'Report filter was successfully updated.'
          format.html { redirect_to :back }
          format.xml  { head :ok }
      else
        format.html { redirect_to :back }
        format.xml  { render :xml => @report_embeddable_filter.errors, :status => :unprocessable_entity }
      end

    end
  end

  # report shown to students
  def student_report
    @offering = Portal::Offering.find(params[:id])
    # PUNDIT_REVIEW_AUTHORIZE
    authorize @offering, :show
    @learner = @offering.learners.find_by_student_id(current_visitor.portal_student)
    if (@learner && @offering)
      reportUtil = Report::Util.reload_without_filters(@offering)  # force a reload of this offering without filters
      @learners = reportUtil.learners
      @page_elements = reportUtil.page_elements
      render :layout => false # student_report.html.haml
      # will render student_report.html.haml
    else
      render :nothing => true
    end
  end

  def setup_portal_student
    # PUNDIT_REVIEW_AUTHORIZE
    # PUNDIT_CHOOSE_AUTHORIZE
    # no authorization needed ...
    # authorize Portal::Offering
    # authorize @offering
    # authorize Portal::Offering, :new_or_create?
    # authorize @offering, :update_edit_or_destroy?
    learner = nil
    if portal_student = current_visitor.portal_student
      # create a learner for the user if one doesnt' exist
      learner = @offering.find_or_create_learner(portal_student)
    end
    learner
  end

  def answers
    @offering = Portal::Offering.find(params[:id])
    # PUNDIT_REVIEW_AUTHORIZE
    authorize @offering, :show
    if @offering
      learner = setup_portal_student
      if learner && params[:questions]
        # create saveables
        params[:questions].each do |dom_id, value|
          # translate the dom id into an actual Embeddable
          embeddable = parse_embeddable(dom_id)
          # create saveable
          create_saveable(embeddable, @offering, learner, value) if embeddable
        end
        learner.report_learner.last_run = DateTime.now
        learner.report_learner.update_fields
      end
      flash[:notice] = "Your answers have been saved."
      redirect_to :home
    else
      render :text => 'problem loading offering', :status => 500
    end
  end

  def offering_collapsed_status
    # PUNDIT_REVIEW_AUTHORIZE
    # PUNDIT_CHOOSE_AUTHORIZE
    # no authorization needed ...
    # authorize Portal::Offering
    # authorize @offering
    # authorize Portal::Offering, :new_or_create?
    # authorize @offering, :update_edit_or_destroy?
    if current_visitor.portal_teacher.nil?
      render :nothing=>true
      return
    end
    offering_collapsed = true
    teacher_id = current_visitor.portal_teacher.id
    portal_teacher_full_status = Portal::TeacherFullStatus.find_or_create_by_offering_id_and_teacher_id(params[:id],teacher_id)

    offering_collapsed = (portal_teacher_full_status.offering_collapsed.nil?)? false : !portal_teacher_full_status.offering_collapsed

    portal_teacher_full_status.offering_collapsed = offering_collapsed
    portal_teacher_full_status.save!

    render :nothing=>true

  end

  def get_recent_student_report
    offering = Portal::Offering.find(params[:id])
    # PUNDIT_REVIEW_AUTHORIZE
    authorize @offering, :show
    students = offering.clazz.students
    if !students.nil? && students.length > 0
      students = students.sort{|a,b| a.user.full_name.downcase<=>b.user.full_name.downcase}
    end
    learners = offering.learners
    progress_report = ""
    div_id = "DivHideShowDetail"+ offering.id.to_s
    render :update do |page|
      page.replace_html(div_id, :partial => "home/recent_student_report", :locals => { :offering => offering, :students=>students, :learners=>learners})
      page << "setRecentActivityTableHeaders(null,#{params[:id]})"
    end
    return
  end

  private

  def parse_embeddable(dom_id)
    # make sure to support at least Embeddable::OpenResponse, Embeddable::MultipleChoice, and Embeddable::MultipleChoiceChoice
    if dom_id =~ /embeddable__([^\d]+)_(\d+)$/
      klass = "Embeddable::#{$1.classify}".constantize
      return klass.find($2.to_i) if klass
    end
    nil
  end

  def create_saveable(embeddable, offering, learner, answer)
    case embeddable
    when Embeddable::OpenResponse
      saveable_open_response = Saveable::OpenResponse.find_or_create_by_learner_id_and_offering_id_and_open_response_id(learner.id, offering.id, embeddable.id)
      if saveable_open_response.response_count == 0 || saveable_open_response.answers.last.answer != answer
        saveable_open_response.answers.create(:bundle_content_id => nil, :answer => answer)
      end
    when Embeddable::MultipleChoice
      choice = parse_embeddable(answer)
      answer = choice ? choice.choice : ""
      if embeddable && choice
        saveable = Saveable::MultipleChoice.find_or_create_by_learner_id_and_offering_id_and_multiple_choice_id(learner.id, offering.id, embeddable.id)
        if saveable.answers.empty? || saveable.answers.last.answer.first[:answer] != answer
          saveable_answer = saveable.answers.create(:bundle_content_id => nil)
          Saveable::MultipleChoiceRationaleChoice.create(:choice_id => choice.id, :answer_id => saveable_answer.id)
        end
      else
        if ! choice
          logger.error("Missing Embeddable::MultipleChoiceChoice id: #{choice_id}")
        elsif ! embeddable
          logger.error("Missing Embeddable::MultipleChoice id: #{choice.multiple_choice_id}")
        end
      end
    else
      nil
    end
  end

end
