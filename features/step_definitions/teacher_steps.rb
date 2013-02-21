When /^I select a school from the list of schools$/ do
  page.evaluate_script("useDefaultSchool();")
end


Then /^I should see the the teacher signup form$/ do
  Then I should see "Teacher Signup Page"
  And I should see "personal info"
  And I should see "school"
  And I should see "login info"
end

Then /^the teachers "([^"]*)" are in a school named "([^"]*)"$/ do |teachers,school_name|
  school = Portal::School.find_by_name(school_name)
  if (school.nil?) then
    school = Factory(:portal_school, :name=>school_name)
  end
  teachers = teachers.split(",").map { |t| t.strip }
  teachers.map! {|t| User.find_by_login(t)}
  teachers.map! {|u| u.portal_teacher }
  teachers.each {|t| t.schools = [ school ]; t.save!; t.reload}
end

Given /^the following teacher and class mapping exists:$/ do |teacher_clazz|
  teacher_clazz.hashes.each do |hash|
    portal_clazz = Portal::Clazz.find_by_name(hash['class_name'])
    user = User.find_by_login(hash['teacher'])
    portal_teacher = Portal::Teacher.find_by_user_id(user.id)
    teacher_clazz = Portal::TeacherClazz.new()
    teacher_clazz.clazz_id = portal_clazz.id
    teacher_clazz.teacher_id = portal_teacher.id
    save_result = teacher_clazz.save
    if (save_result == false)
      return save_result
    end
  end
end

When /^I run the student's investigation$/ do
  visit path_to('the class page for "My Class"')
  within(".accordion_content") do
    click_link 'Run'
  end
end
