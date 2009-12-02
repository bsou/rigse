class Portal::TeacherClazz < ActiveRecord::Base
  set_table_name :portal_teacher_clazzes
  
  acts_as_replicatable
  
  belongs_to :clazz, :class_name => "Portal::Clazz", :foreign_key => "clazz_id"
  belongs_to :teacher, :class_name => "Portal::Teacher", :foreign_key => "teacher_id"
  
  [:name, :description].each { |m| delegate m, :to => :clazz }
  
  # def before_validation
  #   # Portal::TeacherClazz.count(:conditions => "`clazz_id` = '#{self.clazz_id}' AND `teacher_id` = '#{self.teacher_id}'") == 0
  #   sc = Portal::TeacherClazz.find(:first, :conditions => "`clazz_id` = '#{self.clazz_id}' AND `teacher_id` = '#{self.teacher_id}'")
  #   self.id = sc.id
  # end
  
end
