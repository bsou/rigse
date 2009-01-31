class GradeSpanExpectationsController < ApplicationController

  # PUT /grade_span_expectations/reparse_gses
  def reparse_gses
    parser = Parser.new
    respond_to do |format|
      flash[:notice] = 'Grade Span Expectations reparsed from rigse_data.xhtml'
      format.html { redirect_to :action => 'index' }
      format.xml  { head :ok }
    end    
  end
  
  # GET /grade_span_expectations
  # GET /grade_span_expectations.xml
  def index
    # @grade_span_expectations = GradeSpanExpectation.find(:all, :include => :assessment_target)

    @grade_span_expectations = GradeSpanExpectation.search(params[:search], params[:page], self.current_user)
    @paginated_objects = @grade_span_expectations

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @grade_span_expectations }
    end
  end

  # GET /grade_span_expectations/1
  # GET /grade_span_expectations/1.xml
  def show
    @grade_span_expectation = GradeSpanExpectation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @grade_span_expectation }
    end
  end

  # GET /grade_span_expectations/new
  # GET /grade_span_expectations/new.xml
  def new
    @grade_span_expectation = GradeSpanExpectation.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @grade_span_expectation }
    end
  end

  # GET /grade_span_expectations/1/edit
  def edit
    @grade_span_expectation = GradeSpanExpectation.find(params[:id])
  end

  # POST /grade_span_expectations
  # POST /grade_span_expectations.xml
  def create
    @grade_span_expectation = GradeSpanExpectation.new(params[:grade_span_expectation])

    respond_to do |format|
      if @grade_span_expectation.save
        flash[:notice] = 'GradeSpanExpectation was successfully created.'
        format.html { redirect_to(@grade_span_expectation) }
        format.xml  { render :xml => @grade_span_expectation, :status => :created, :location => @grade_span_expectation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @grade_span_expectation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /grade_span_expectations/1
  # PUT /grade_span_expectations/1.xml
  def update
    @grade_span_expectation = GradeSpanExpectation.find(params[:id])

    respond_to do |format|
      if @grade_span_expectation.update_attributes(params[:grade_span_expectation])
        flash[:notice] = 'GradeSpanExpectation was successfully updated.'
        format.html { redirect_to(@grade_span_expectation) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @grade_span_expectation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /grade_span_expectations/1
  # DELETE /grade_span_expectations/1.xml
  def destroy
    @grade_span_expectation = GradeSpanExpectation.find(params[:id])
    @grade_span_expectation.destroy

    respond_to do |format|
      format.html { redirect_to(grade_span_expectations_url) }
      format.xml  { head :ok }
    end
  end
end
