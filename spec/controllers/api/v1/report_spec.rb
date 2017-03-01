require 'spec_helper'

include ReportLearnerSpecHelper # defines : saveable_for : answers_for : add_answer : stub_all_reportables

RSpec::Matchers.define :include_hash do |comp_hash|
  match do |actual|
    found = false
    actual.each do |test|
      hash_matched = true
      comp_hash.each_pair do |key,value|
        hash_matched = hash_matched && test.has_key?(key) && test[key] == value
      end
      found = hash_matched
      break if found
    end
    found
  end
end

describe API::V1::ReportsController do
  let(:open_response)     { Factory.create(:open_response)}
  let(:section)           { Factory.create(:section) }
  let(:page)              { Factory.create(:page) }
  let(:runnable)          { Factory.create(:activity, runnable_opts)    }
  let(:offering)          { Factory(:portal_offering, offering_opts)    }
  let(:clazz)             { Factory(:portal_clazz, teachers: [class_teacher], students:[student_a,student_b]) }
  let(:offering_opts)     { {clazz: clazz, runnable: runnable}  }
  let(:runnable_opts)     { {name: 'the activity'}              }
  let(:class_teacher)     { Factory.create(:portal_teacher)     }
  let(:learner_a)         { Portal::Learner.find_or_create_by_offering_id_and_student_id(offering.id, student_a.id )}
  let(:learner_b)         { Portal::Learner.find_or_create_by_offering_id_and_student_id(offering.id, student_b.id )}
  let(:student_a)         { FactoryGirl.create(:full_portal_student) }
  let(:student_b)         { FactoryGirl.create(:full_portal_student) }
  let(:report_learner_a)  { learner_a.report_learner }
  let(:report_learner_b)  { learner_b.report_learner }
  let(:user)              { class_teacher.user       }
  let(:learner)           { learner_a }

  def json_path(path_string)
    json =  JSON.parse(response.body)

    path_string.split(".").each do |segment|
      json = json[segment]
    end
    json
  end

  def update(opts)
    put :update, opts
  end

  def show
    get :show, :id => offering.id
  end

  def question
    json_path("report.children")[0]['children'][0]['children'][0]
  end

  def answers
    question['answers']
  end

  def feedback_should_be_enabled
    expect(question).to include({"feedback_enabled" => true})
  end

  def feedback_should_be_disabled
    expect(question).to include({"feedback_enabled" => false})
  end

  def score_should_be_enabled
    expect(question).to include({"score_enabled" => true})
  end

  def score_should_be_disabled
    expect(question).to include({"score_enabled" => false})
  end

  def max_score_should_be(value)
    expect(question).to include({"max_score" => value})
  end

  before(:each) do
    page.add_embeddable(open_response)
    section.pages << page
    runnable.sections << section
    runnable.save
    allow(Portal::Offering).to receive(:find).and_return(offering)
    sign_in user
    add_answer_for_learner(learner_a, open_response, {"answer" => "testing from #{learner_a.student.user.id}"} )
    add_answer_for_learner(learner_b, open_response, {"answer" => "testing from #{learner_b.student.user.id}"} )
    report_learner_a.update_answers()
    report_learner_b.update_answers()
    report_learner_a.save
    report_learner_b.save
  end


  describe "GET show" do
    describe "For the offering's teacher" do
      it 'it should render the report json' do
        show
        expect(response.status).to eql(200)
        expect(json_path("report_version")).to eql "1.0.2"
        expect(json_path("report.name")).to eql "the activity"
        expect(json_path("class.students")).to include_hash({"started_offering"=>true, "name"=>"joe user"})
        max_score_should_be 0
        feedback_should_be_disabled
        score_should_be_disabled
        expect(answers).to include_hash({"answer" => "testing from #{learner_a.student.user.id}"})
      end
    end
  end

  describe "changing the view filter" do
    let(:active)             { false }
    let(:questions)          { [] }
    let(:visibility_filter)  { { questions: questions, active: active} }
    let(:opts) { {id: offering.id, visibility_filter: visibility_filter } }

    describe "to off" do
      let(:active)             { false }
      it "should save the filter settings" do
        update opts
        show
        expect(response.status).to eql 200
        expect(json_path("visibility_filter.active")).to be_falsey
      end
    end

    describe "to on" do
      let(:active)             { true }
      it "should save the filter settings" do
        update(opts)
        show
        expect(response.status).to eql(200)
        expect(json_path("visibility_filter.active")).to be_truthy
      end
    end
  end

  describe "enabling feedback options for a question in the report" do
    let(:enable_feedback)     { false }
    let(:enable_score)        { false }
    let(:max_score)            { 0 }
    let(:embeddable_key)       { API::V1::Report.embeddable_key(open_response) }
    let(:feedback_opts)        do
      {
          'embeddable_key'       => embeddable_key ,
          'enable_text_feedback' => enable_feedback,
          'enable_score'         => enable_score,
          'max_score'            => max_score
      }
    end
    let(:opts) { {id: offering.id, feedback_opts: feedback_opts} }
    # enable_feedback(offering, question, feedback_enabled, score_enabled, max_score)
    describe "when disabling feedback for our question" do
      it "should disable feedback for our question" do
        update(opts)
        show
        expect(response.status).to eql(200)
        md = Portal::OfferingEmbeddableMetadata.find_by_offering_id_and_embeddable_id_and_embeddable_type(offering.id, open_response.id, open_response.class.name)
        expect(md.enable_text_feedback).to be_falsey
        expect(md.enable_score).to be_falsey
        expect(md.max_score).to eq 0
      end
    end

    describe "when enabling score only for our question" do
      let(:enable_score)  { true }
      it "should disable feedback for our question" do
        update(opts)
        show
        expect(response.status).to eql(200)
        md = Portal::OfferingEmbeddableMetadata.find_by_offering_id_and_embeddable_id_and_embeddable_type(offering.id, open_response.id, open_response.class.name)
        expect(md.enable_text_feedback).to be_falsey
        expect(md.enable_score).to be_truthy
        expect(md.max_score).to eq 0
      end
    end

    describe "when chaging the max score to 20" do
      let(:max_score)   { 20 }
      it "should disable feedback for our question" do
        update(opts)
        show
        expect(response.status).to eql(200)
        md = Portal::OfferingEmbeddableMetadata.find_by_offering_id_and_embeddable_id_and_embeddable_type(offering.id, open_response.id, open_response.class.name)
        expect(md.enable_text_feedback).to be_falsey
        expect(md.enable_score).to be_falsey
        expect(md.max_score).to eq 20
      end
    end
  end

end