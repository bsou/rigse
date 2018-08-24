require 'spec_helper'

describe API::V1::SearchController do
  include SolrSpecHelper

  def make(let); end

  let(:admin_settings)   { Factory.create(:admin_settings, :include_external_activities => false) }

  let(:mock_school)     { Factory.create(:portal_school) }

  let(:teacher_user)    { Factory.create(:confirmed_user, :login => "teacher_user") }
  let(:teacher)         { Factory.create(:portal_teacher, :user => teacher_user, :schools => [mock_school]) }
  let(:admin_user)      { Factory.next(:admin_user) }
  let(:author_user)     { Factory.next(:author_user) }
  let(:manager_user)    { Factory.next(:manager_user) }
  let(:researcher_user) { Factory.next(:researcher_user) }

  let(:student_user)    { Factory.create(:confirmed_user, :login => "authorized_student") }
  let(:student)         { Factory.create(:portal_student, :user_id => student_user.id) }

  let(:physics_investigation)     { Factory.create(:investigation, :name => 'physics_inv', :user => author_user, :publication_status => 'published') }
  let(:chemistry_investigation)   { Factory.create(:investigation, :name => 'chemistry_inv', :user => author_user, :publication_status => 'published') }
  let(:biology_investigation)     { Factory.create(:investigation, :name => 'mathematics_inv', :user => author_user, :publication_status => 'published') }
  let(:mathematics_investigation) { Factory.create(:investigation, :name => 'biology_inv', :user => author_user, :publication_status => 'published') }
  let(:lines)                     { Factory.create(:investigation, :name => 'lines_inv', :user => author_user, :publication_status => 'published') }

  let(:laws_of_motion_activity)  { Factory.create(:activity, :name => 'laws_of_motion_activity' ,:investigation_id => physics_investigation.id, :user => author_user) }
  let(:fluid_mechanics_activity) { Factory.create(:activity, :name => 'fluid_mechanics_activity' , :investigation_id => physics_investigation.id, :user => author_user) }
  let(:thermodynamics_activity)  { Factory.create(:activity, :name => 'thermodynamics_activity' , :investigation_id => physics_investigation.id, :user => author_user) }
  let(:parallel_lines)           { Factory.create(:activity, :name => 'parallel_lines' , :investigation_id => lines.id, :user => author_user) }

  let(:external_activity1)   { Factory.create(:external_activity, 
                                        :name => 'external_1', 
                                        :url => "http://concord.org", 
                                        :publication_status => 'published', 
                                        :is_official => true,
                                        :material_type => 'Activity' ) }

  let(:external_activity2)   { Factory.create(:external_activity, 
                                        :name => 'a_study_in_lines_and_curves', 
                                        :url => "http://github.com", 
                                        :publication_status => 
                                        'published', 
                                        :is_official => true,
                                        :material_type => 'Activity' ) }


  let(:external_activity3)   { Factory.create(:external_activity,
                                        :name => 'a_study_in_lines_and_curves',
                                        :url => "http://github.com",
                                        :publication_status =>
                                        'published',
                                        :is_official => true,
                                        :material_type => 'Investigation' ) }


  let(:contributed_activity) { Factory.create(:external_activity,
                                        :name => "Copy of external_1",
                                        :url => "http://concord.org",
                                        :publication_status => 'published',
                                        :is_official => false,
                                        :material_type => 'Activity' ) }

  let(:all_investigations)    { [physics_investigation, chemistry_investigation, biology_investigation, mathematics_investigation, lines, external_activity3]}
  let(:official_activities)   { [laws_of_motion_activity, fluid_mechanics_activity, thermodynamics_activity, parallel_lines, external_activity1, external_activity2]}
  let(:contributed_activities){ [contributed_activity] }
  let(:all_activities)        {  official_activities.concat(contributed_activities) }
  let(:investigation_results) { [] }
  let(:activity_results)      { [] }

  let(:search_results) {{ Investigation => investigation_results, Activity => activity_results }}
  let(:mock_search)    { double('results', {:results => search_results})}

  before(:all) do
    solr_setup
    clean_solar_index
  end

  after(:each) do
    clean_solar_index
  end

  before(:each) do
    admin_settings
    sign_in teacher_user
    make all_investigations
    make official_activities
    make contributed_activities
    make all_activities
    Sunspot.commit_if_dirty
  end

  describe "GET search" do

    describe "searching for materials" do
      let(:get_params) { {} }
      before(:each) do
        get :search, get_params
      end

      describe "with no filter parameters" do
        it "should return search results that shows only external activity based materials" do
          expect(assigns[:search]).not_to be_nil
          expect(assigns[:search].results[Search::InvestigationMaterial]).not_to be_nil
          expect(assigns[:search].results[Search::InvestigationMaterial].length).to be(1)
          assigns[:search].results[Search::InvestigationMaterial].each do |investigation|
            expect(all_investigations).to include(investigation)
          end
          expect(assigns[:search].results[Search::ActivityMaterial]).not_to be_nil
          expect(assigns[:search].results[Search::ActivityMaterial].length).to be(3)
          assigns[:search].results[Search::ActivityMaterial].each do |activity|
            expect(all_activities).to include(activity)
          end
        end
      end

      describe "searching only official materials" do
        let(:get_params) { {:include_official => 1} }
        it "should show all official study materials" do
          expect(assigns[:search].results[Search::InvestigationMaterial]).not_to be_nil
          expect(assigns[:search].results[Search::InvestigationMaterial].length).to be(1)
          assigns[:search].results[Search::InvestigationMaterial].each do |investigation|
            expect(all_investigations).to include(investigation)
          end
          expect(assigns[:search].results[Search::ActivityMaterial]).not_to be_nil
          expect(assigns[:search].results[Search::ActivityMaterial].length).to be(2)
          assigns[:search].results[Search::ActivityMaterial].each do |activity|
            expect(official_activities).to include(activity)
          end
        end

        it "should not return any contributed activities" do
          assigns[:search].results[Search::ActivityMaterial].each do |activity|
            expect(contributed_activities).not_to include(activity)
          end
        end
      end

      describe "searching only investigations" do
        let(:get_params) { {:material_types => [Search::InvestigationMaterial]} }
        let(:activity_results) {[]}

        it "should return all investigations" do
          expect(assigns[:search].results[Search::InvestigationMaterial]).not_to be_nil
          expect(assigns[:search].results[Search::InvestigationMaterial].length).to be(1)
        end

        it "should not return any activities" do
          get :search, get_params
          expect(assigns[:search].results[Search::ActivityMaterial]).to be_nil
        end
      end

      describe "searching only activities" do
        let(:get_params) {{:material_types => [Search::ActivityMaterial]}}
        it "should not include investigations" do
          expect(assigns[:search].results[Search::InvestigationMaterial]).to be_nil
        end
        it "should return all activities" do
          expect(assigns[:search].results[Search::ActivityMaterial]).not_to be_nil
          expect(assigns[:search].results[Search::ActivityMaterial].length).to be(3)
          assigns[:search].results[Search::ActivityMaterial].each do |activity|
            expect(all_activities).to include(activity)
          end
        end
        describe "including contributed activities" do
          let(:get_params) {{ :material_types => ['Activity'], :include_contributed => 1 }}
          it "should include contributed activities" do
            expect(assigns[:search].results[Search::ActivityMaterial].length).to eq(1)
            expect(assigns[:search].results[Search::ActivityMaterial]).to include(contributed_activity)
          end
        end
      end
    end
  end
end
