require 'spec_helper'
require 'delorean'

# Test authentication clients
describe Client do
  let(:domain_machers) { nil }
  let(:client) do
    Client.create(
      app_id: 'testing-client',
      app_secret: 'xyzzy',
      name: 'testing-client',
      site_url: 'http://localhost:8080/',
      domain_matchers: domain_machers
    )
  end
  context "a client that isn't restricted to various domains" do
    it "should validate from any domain" do
      expect(client).to be_valid_from_referer("http://blargonaut.com/")
      expect(client).to be_valid_from_referer("http://foo.com/blarg.html")
    end
  end
  context "a client that has domains matchers set to whitespace" do
    let(:domain_matchers) { "    \t\n   " }
    it "should validate from any domain" do
      expect(client).to be_valid_from_referer("http://blargonaut.com/")
      expect(client).to be_valid_from_referer("http://foo.com/blarg.html")
    end
  end
  context "a client that only works for foo.com or baz.com domains" do
    let(:domain_machers) { "foo.com baz.com" }
    it "should not validate for referers of blargonaut" do
      expect(client.valid_from_referer?("http://blargonaut.com/")).to be_falsey
      expect(client.valid_from_referer?("http://blargonaut.com/foo.com")).to be_falsey
      expect(client.valid_from_referer?("http://blargonaut.com/baz.com")).to be_falsey
    end
    it "should not validate if HTTP_REFERER is missing" do
      expect(client.valid_from_referer?("")).to be_falsey
    end
    it "should validate for referers of foo.com" do
      expect(client.valid_from_referer?("http://foo.com")).to be_truthy
      expect(client.valid_from_referer?("https://foo.com/")).to be_truthy
      expect(client.valid_from_referer?("https://foo.com/index.html")).to be_truthy
    end
    it "should validate for referers of baz.com" do
      expect(client.valid_from_referer?("http://baz.com")).to be_truthy
      expect(client.valid_from_referer?("https://baz.com/")).to be_truthy
      expect(client.valid_from_referer?("https://baz.com/index.html")).to be_truthy
    end
  end
  describe "a client with an access_grant" do
    let(:user)  { FactoryBot.create(:user) }
    before(:each) do
      user.access_grants.create(client_id: client.id )
      user.reload
      client.reload
    end
    it "should a valid access_grant" do
      expect(client.access_grants.size).to eq(1)
      expect(user.access_grants.size).to eq(1)
    end

    describe "deting the client" do
      before(:each) do
        client.destroy
        user.reload
      end
      it "should remove the grants from the users" do
        expect(user.access_grants.size).to eq(0)
      end
    end
  end


  # TODO: auto-generated
  describe '.authenticate' do
    it 'authenticate' do
      app_id = double('app_id')
      app_secret = double('app_secret')
      result = described_class.authenticate(app_id, app_secret)

      expect(result).to be_nil
    end
  end

  # TODO: auto-generated
  describe '#valid_from_referer?' do
    it 'valid_from_referer?' do
      client = described_class.new
      referer = double('referer')
      result = client.valid_from_referer?(referer)

      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#enforce_referrer?' do
    it 'enforce_referrer?' do
      client = described_class.new
      result = client.enforce_referrer?

      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#updated_grant_for' do
    xit 'updated_grant_for' do
      client = described_class.new
      user = FactoryBot.create(:user)
      time_to_live = double('time_to_live')
      result = client.updated_grant_for(user, time_to_live)

      expect(result).not_to be_nil
    end
  end


end
