class Portal::Grade < ActiveRecord::Base
  set_table_name :portal_grades
  
  acts_as_list

  acts_as_replicatable

  named_scope :active, { :conditions => { :active => true } }  

  has_many :grade_levels, :class_name => "Portal::GradeLevel"
  
  self.extend SearchableModel

  @@searchable_attributes = %w{name description}

  class <<self
    def searchable_attributes
      @@searchable_attributes
    end

    def display_name
      "Grade"
    end
  end
  
end
