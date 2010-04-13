Given /^I am not logged in$/ do
  # pending # express the regexp above with the code you wish you had
  # controller.current_user = User.anonymous
end

# dont use webrat for these, because of sessions:
When /^I visit the route (.+)$/ do |route|
  visit route
end

Then /^I should be redirected (.+)$/ do |named_route|
  response.should redirect_to(named_route)
end

Then /^I should not be redirected (.+)$/ do |named_route|
  response.should_not redirect_to(named_route)
end
