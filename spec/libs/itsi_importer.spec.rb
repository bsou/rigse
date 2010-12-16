require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ItsiImporter do
  before(:all) do
  end
  # def process_diy_activity_section(actvity,diy_act,section_key,section_name,section_description) 
  describe "process diy activity section" do
    before(:each) do
      @sections = []
      @activity = mock_model(Activity,
          :investigation => mock_model(Investigation,
            :update_attribute => true))
      @diy_act = mock_model(Itsi::Activity,
          :collect_data => "Collect Data Rich text",
          :update_attribute => true)
      @section_key = "collect_data"
      @section_name = "Collect Data"
      @section_description = "go out there and get me some data!"
    end
    
    def call_process_diy_activity_section 
      ItsiImporter.process_diy_activity_section(@activity,@diy_act,@section_key,@section_name,@section_description)
    end

    it "should respond to the method named process_diy_activity_section" do
      ItsiImporter.should respond_to :process_diy_activity_section
    end
    
    it "should add a section and a page to the activity that are well named" do
      @activity.should_receive(:sections).and_return(@sections)
      call_process_diy_activity_section
      @sections.should have(1).section
      @sections.first.should be_an_instance_of Section
      @sections.first.name.should be @section_name
    end
    
    it "should create appropriate embeddedables" do
      @activity.should_receive(:sections).and_return(@sections)
      @diy_act.should_receive(:respond_to?).with(:collect_data_text_response).and_return(true)
      @diy_act.should_receive(:respond_to?).with(:collect_data_drawing_response).and_return(true)
      @diy_act.should_receive(:respond_to?).with(:probe_type_id).and_return(true)
      Embeddable::DataCollector.stub!(:prototype_by_type_and_calibration => Factory(:data_collector))
      # respond with these answers:
      @diy_act.should_receive(:collect_data_drawing_response).and_return(false)
      @diy_act.should_receive(:collect_data_text_response).and_return(true)
      @diy_act.should_receive(:collectdata1_calibration_active).and_return(true)
      @diy_act.should_receive(:collect_data_probe_active ).and_return(true)
      @diy_act.should_receive(:collectdata1_calibration_id).and_return(1)
      @diy_act.should_receive(:probe_type_id).and_return(1)
      
      # dont handle these types:
      @diy_act.should_receive(:respond_to?).with(:collect_data_model_active).and_return(false)
      call_process_diy_activity_section
      page = @sections.first.pages.first
      # should have a diy:section, a diy:sensor, and a drawing_response
      page.should have(3).page_elements
      # but the drawing_response is disabled:
      page.page_elements.select{ |e| e.is_enabled}.should have(2).enabled
    end

  end
  
  describe "create_activity_from_itsi_activity method" do
    def call_create_activity(act = @itsi_activity, user = @user)
      ItsiImporter.create_activity_from_itsi_activity(act,user)
    end
    
    before(:each) do
      @itsi_activity = mock_model(Itsi::Activity,
          :name => "fake diy activity",
          :description => "fake diy activity")
      @user = mock_model(User,
          :login => "fake_user",
          :first_name => "fake",
          :last_name => "user",
          :name => "fake user",
          :add_role => true)
    end

    it "should respond to create_activity_from_itsi_activity" do
      ItsiImporter.should respond_to :create_activity_from_itsi_activity
    end

    it "should try to create all the required sections" do
      expected_calls = ItsiImporter::SECTIONS_MAP.size
      ItsiImporter::SECTIONS_MAP.map{ |e| e[:key] }.each do |key|
        @itsi_activity.should_receive(key).and_return("some text")
        [:text_response, :drawing_response, :model_active, :probetype_id].each do |attribute|
          attribute_key = ItsiImporter.attribute_name_for(key,attribute)
          @itsi_activity.should_receive(:respond_to?).with(attribute_key).and_return(false)
        end
      end
      call_create_activity
    end
  end
end
