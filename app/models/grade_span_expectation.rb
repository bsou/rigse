class GradeSpanExpectation < ActiveRecord::Base
  belongs_to              :user
  has_and_belongs_to_many :expectation_stems
  has_many                :big_ideas
  belongs_to              :assessment_target
  acts_as_replicatable
  
  self.extend SearchableModel
  
  @@searchable_attributes = %w{grade_span}
  
  class <<self
    def searchable_attributes
      @@searchable_attributes
    end
  end
  
end
