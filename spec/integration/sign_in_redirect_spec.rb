require "spec_helper"

describe "when user signs in and 'after_sign_in_path' parameter is provided" do
  let(:user) { FactoryBot.create(:confirmed_user) }
  let(:custom_url) { "/some-foo-bar-path" }

  it "user is redirected back to this page with extra param" do
    post "/users/sign_in", user: {login: user.login, password: user.password}, after_sign_in_path: custom_url
    expect(response).to redirect_to("#{custom_url}?redirecting_after_sign_in=1")
  end

  describe "and user is student" do
    let(:user) { FactoryBot.create(:full_portal_student).user }

    it "user is sent to my classes" do
      post "/users/sign_in", user: {login: user.login, password: user.password}, after_sign_in_path: custom_url
      expect(response).to redirect_to(my_classes_url)
    end
  end
end
