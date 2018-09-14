#
# Dynamically generate our Role Singleton Factories for named roles:
# FactoryGirl.generate :admin_role
# FactoryGirl.generate :member_role
# FactoryGirl.generate :guest_role
#
%w| guest member admin researcher manager author|.each_with_index do |role_name, index|
  Factory.sequence "#{role_name}_role".to_sym do |n|
    role = Role.find_by_title(role_name)
    unless role
      role = FactoryGirl.create(:role, :title => role_name, :position => index)
    end
    role
  end
end


##
## The actual factory for roles doesn't actually do anything at the moment.
##
FactoryGirl.define do
  factory :role do |f|

  end
end

