class Dataservice::ProcessExternalActivityDataJob < Struct.new(:learner_id, :content)
  include SaveableExtraction

  def perform
    all_data = JSON.parse(content) rescue {}
    learner = Portal::Learner.find(learner_id)
    offering = learner.offering
    template = offering.runnable.template
    embeddables = [template.open_responses, template.multiple_choices].flatten.compact.uniq

    # setup for SaveableExtraction
    @learner_id = learner_id
    @offering_id = offering.id

    # process the json data
    all_data.each do |student_response|
      embeddable = embeddables.detect {|e| e.external_id == student_response["question_id"]}
      case student_response["type"]
      when "open_response"
        internal_process_open_response(student_response, embeddable)
      when "multiple_choice"
        internal_process_multiple_choice(student_response, embeddable)
      end
    end
  end

  def internal_process_open_response(data, embeddable)
    process_open_response(embeddable.id, data["answer"])
  end

  def internal_process_multiple_choice(data, embeddable)
    choice_ids = data["answer_ids"].map {|aid| choice = embeddable.choices.detect{|ch| ch.external_id == aid }; choice ? choice.id : nil }
    process_multiple_choice(choice_ids.compact.uniq)
  end

  # stub id method, for SaveableExtraction compatibility
  def id
    nil
  end

end
