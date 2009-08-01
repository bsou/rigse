class RawOtmlsController < ApplicationController
  # GET /raw_otmls
  # GET /raw_otmls.xml
  def index    
    @raw_otmls = RawOtml.search(params[:search], params[:page], nil)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @raw_otmls}
    end
  end

  # GET /raw_otmls/new
  # GET /raw_otmls/new.xml
  def new
    @raw_otml = RawOtml.new
    if request.xhr?
      render :partial => 'remote_form', :locals => { :raw_otml => @raw_otml }
    else
      respond_to do |format|
        format.html # renders new.html.haml
        format.xml  { render :xml => @raw_otml }
      end
    end
  end

  def show
    @authoring = false
    @raw_otml = RawOtml.find(params[:id])
    if request.xhr?
      render :partial => 'raw_otml', :locals => { :raw_otml => @raw_otml }
    else
      respond_to do |format|
        format.html # show.html.haml
        format.otml { render :layout => "layouts/raw_otml" } # raw_otml.otml.haml
        format.jnlp { render :partial => 'shared/show', :locals => { :runnable => @raw_otml }}
        format.config { render :partial => 'shared/show', :locals => { :runnable => @raw_otml } }
        format.xml  { render :raw_otml => @raw_otml }
      end
    end
  end

  # GET /raw_otmls/1/edit
  def edit
    @authoring = true
    @raw_otml = RawOtml.find(params[:id])
    if request.xhr?
      render :partial => 'remote_form', :locals => { :raw_otml => @raw_otml }
    else
      respond_to do |format|
        format.html 
        format.otml { render :layout => "layouts/raw_otml" } # raw_otml.otml.haml
        format.jnlp { render :partial => 'shared/edit', :locals => { :runnable => @raw_otml } }
        format.xml  { render :xml => @raw_otml  }
      end
    end
  end
  

  # POST /raw_otmls
  # POST /raw_otmls.xml
  def create
    @raw_otml = RawOtml.new(params[:raw_otml])
    cancel = params[:commit] == "Cancel"
    if request.xhr?
      if cancel 
        redirect_to :index
      elsif @raw_otml.save
        render :partial => 'new', :locals => { :raw_otml => @raw_otml }
      else
        render :xml => @raw_otml.errors, :status => :unprocessable_entity
      end
    else
      respond_to do |format|
        if @raw_otml.save
          flash[:notice] = 'Rawotml was successfully created.'
          format.html { redirect_to(@raw_otml) }
          format.xml  { render :xml => @raw_otml, :status => :created, :location => @raw_otml }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @raw_otml.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /raw_otmls/1
  # PUT /raw_otmls/1.xml
  def update
    cancel = params[:commit] == "Cancel"
    @raw_otml = RawOtml.find(params[:id])
    if request.xhr?
      if cancel || @raw_otml.update_attributes(params[:raw_otml])
        render :partial => 'show', :locals => { :raw_otml => @raw_otml }
      else
        render :xml => @raw_otml.errors, :status => :unprocessable_entity
      end
    elsif request.symbolized_path_parameters[:format] == 'otml'
      otml_content = (Hpricot.XML(request.raw_post)/'/otrunk/objects/OTSystem/root/*').to_s
      @raw_otml.update_attributes(:otml_content => otml_content)
      render :nothing => true
    else
      respond_to do |format|
        if @raw_otml.update_attributes(params[:raw_otml])
          flash[:notice] = 'Raw otml was successfully updated.'
          format.html { redirect_to(@raw_otml) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @raw_otml.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # DELETE /raw_otmls/1
  # DELETE /raw_otmls/1.xml
  def destroy
    @raw_otml = RawOtml.find(params[:id])
    respond_to do |format|
      format.html { redirect_to(raw_otmls_url) }
      format.xml  { head :ok }
      format.js
    end
    
    # TODO:  We should move this logic into the model!
    @raw_otml.page_elements.each do |pe|
      pe.destroy
    end
    @raw_otml.destroy    
  end
end
