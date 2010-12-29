require 'spec_helper'
describe Embeddable::DataCollector do

  describe "When there are existing probes" do
    before(:all) do
      @fake_probe= mock_model(Probe::ProbeType,
        :name => 'fake', :id => 1)
      Probe::ProbeType.stub!(:find_by_name => @fake_probe)
      Probe::ProbeType.stub!(:find => @fake_probe)
    end

    it_should_behave_like 'a cloneable model'

    it "should create a new instance given valid attributes" do
      data_collector = Embeddable::DataCollector.new
      data_collector.save
      data_collector.probe_type.should_not be_nil
      data_collector.probe_type.id.should_not be_nil
      data_collector.should be_valid
    end

    it "should use a good default and valid probe_type" do
      data_collector = Embeddable::DataCollector.create
      data_collector.probe_type.should_not be_nil
      data_collector.should be_valid
    end

    it "should fail validation if the probe_type_id is wrong" do
      data_collector = Embeddable::DataCollector.new
      data_collector.probe_type_id = 9999
      data_collector.save
      data_collector.should_not be_valid
    end

    describe "Embeddable::DataCollector.prototype_by_type_and_calibration" do
      it "should find and use an existing datacollector prototype with a known probeType" do
        @fake_probe_a = mock_model(Probe::ProbeType, :name => "type a", :id => 2)
        moc_data_collector = mock_model(Embeddable::DataCollector,
                               :probe_type => @fake_probe_a)
        prototypes = mock(:find => moc_data_collector)
        Embeddable::DataCollector.stub(:prototypes => prototypes)

        proto = Embeddable::DataCollector.prototype_by_type_and_calibration(@fake_probe_a,nil)
        proto.probe_type.should == @fake_probe_a
      end
      
      it "should create a datacollector with the given probeType, when an existing prototype cant be found" do
        @fake_probe_a = mock_model(Probe::ProbeType, :name => "type a", :id => 2)
        prototypes = mock(:find => nil)
        Embeddable::DataCollector.stub(:prototypes => prototypes)
        proto = Embeddable::DataCollector.prototype_by_type_and_calibration(@fake_probe_a,nil)
        proto.probe_type.should == @fake_probe_a
      end

      it "should use the name of the probeType for the name of the dataCollector when making a new prototype" do
        @fake_probe_a = mock_model(Probe::ProbeType, :name => "type a", :id => 2)
        prototypes = mock(:find => nil)
        Embeddable::DataCollector.stub(:prototypes => prototypes)
        proto = Embeddable::DataCollector.prototype_by_type_and_calibration(@fake_probe_a,nil)
        proto.probe_type.should == @fake_probe_a
        proto.name.should match @fake_probe_a.name
      end
    end

  end

  describe "When no probes exist" do
    # todo: whats the behavior here?
    before(:all) do
      Probe::ProbeType.stub!(:find_by_name => nil)
      Probe::ProbeType.stub!(:find => nil)
      Probe::ProbeType.stub!(:default => nil)
    end

    it "should fail validation" do
      data_collector = Embeddable::DataCollector.create
      data_collector.should_not be_valid
    end

    it "Present a good validation message, and log the error" do
      data_collector = Embeddable::DataCollector.create
      data_collector.should_not be_valid
      data_collector.errors.on(:probe_type).should include(Embeddable::DataCollector::MISSING_PROBE_MESSAGE)
    end
  end
end
