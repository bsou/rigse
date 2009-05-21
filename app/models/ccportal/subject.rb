class Ccportal::Subject < Ccportal::Ccportal
  set_table_name :portal_subjects
  set_primary_key :subject_id
  
  has_many :activities, :foreign_key => :activity_subject, :class_name => 'Ccportal::Activity'
end
