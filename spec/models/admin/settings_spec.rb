require File.expand_path('../../../spec_helper', __FILE__)

describe Admin::Settings do
  before(:each) do
    @new_valid_settings = Admin::Settings.new(
      :active => true
    )
  end

  it "should create a new instance given valid attributes" do
    @new_valid_settings.should be_valid
  end


  describe "pub_interval" do
    describe "default value" do
      it "should be 5 minutes" do
        five_min = 300
        @new_valid_settings.pub_interval.should == five_min
      end
    end

    describe "less than minimum interval" do
      it "should fail validations" do
        @new_valid_settings.pub_interval = Admin::Settings::MinPubInterval - 1
        @new_valid_settings.should_not be_valid
        puts @new_valid_settings.errors
      end
    end

  end
  describe "bookmarks" do

    describe "#available_bookmark_types" do
      subject  { @new_valid_settings.available_bookmark_types }

      it "should return an array" do
        should be_kind_of Array
      end

      it "should include a generic bookmark type" do
        should include Portal::GenericBookmark.name
      end
    end

    describe "#enabled_bookmark_types" do
      subject  { @new_valid_settings.enabled_bookmark_types }
      it "should return an array" do
        should be_kind_of Array
      end

      it "should be empty be default" do
        should be_empty
      end

    end

  end

  describe "class methods" do
    before(:each) do
      @clazz = Admin::Settings
      APP_CONFIG[:test_value_true] = true
      APP_CONFIG[:test_value_false] = false
      APP_CONFIG[:test_value_nil] = nil
    end
    describe "reading configuration settings" do
      describe "settings_for" do
        it "should be a method" do
          @clazz.should respond_to :settings_for
        end
        it "should return true values" do
          @clazz.settings_for(:test_value_true).should be_true
        end
        it "should return false values" do
          @clazz.settings_for(:test_value_false).should be_false
        end
        it "should report nil values" do
          @clazz.should_receive(:notify_missing_setting)
          @clazz.settings_for(:test_value_nil).should be_nil
        end
        it "should report undefined values" do
          @clazz.should_receive(:notify_missing_setting)
          @clazz.settings_for(:something_undefined).should be_nil
        end
      end
    end
    describe "require_activity_descriptions" do
      it "should return the APP_CONFIG settings for :require_activity_descriptions" do
        @clazz.should_receive(:settings_for).with(:require_activity_descriptions).and_return(true)
        @clazz.require_activity_descriptions.should be_true
        @clazz.should_receive(:settings_for).with(:require_activity_descriptions).and_return(false)
        @clazz.require_activity_descriptions.should be_false
      end
    end
    describe "unique_activity_names" do
      it "should return the APP_CONFIG settings for :unique_activity_names" do
        @clazz.should_receive(:settings_for).with(:unique_activity_names).and_return(true)
        @clazz.unique_activity_names.should be_true
        @clazz.should_receive(:settings_for).with(:unique_activity_names).and_return(false)
        @clazz.unique_activity_names.should be_false
      end
    end

    describe "teachers_can_author" do
      let(:active_settings) { mock() }
      it "should return true if the current settings allows teachers to author" do
        @clazz.should_receive(:default_settings).and_return(active_settings)
        active_settings.should_receive(:teachers_can_author).and_return(true)
        @clazz.teachers_can_author?.should == true
      end
      it "should return false if the current settings dissalows teachers authoring" do
        @clazz.should_receive(:default_settings).and_return(active_settings)
        active_settings.should_receive(:teachers_can_author).and_return(false)
        @clazz.teachers_can_author?.should == false
      end
    end
  end

end
