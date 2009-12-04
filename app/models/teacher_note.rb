class TeacherNote < ActiveRecord::Base
  belongs_to :user
  # has_and_belongs_to_many :grade_span_expectations, :join_table => "teacher_notes_grade_spans"
  # has_and_belongs_to_many :domains, :join_table => "teacher_notes_domains"
  # has_and_belongs_to_many :unifying_themes, :join_table => "teacher_notes_unifying_themes"
  
  belongs_to :authored_entity, :polymorphic => true

  acts_as_replicatable
  include Changeable
  
  # send_update_events_to :investigation
  # 
  def after_update
    self.authored_entity.investigation.touch
  end

end
