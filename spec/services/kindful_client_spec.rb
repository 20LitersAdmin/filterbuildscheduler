require 'rails_helper'

RSpec.describe KindfulClient do
  let(:user1) { build :user }
  let(:client) { KindfulClient.new }

  describe "import_user" do
    it 'takes user data and sends it to kindful' do
      http_spy = spy
      body_args = {
        id: 1,
        fname: "Person",
        lname: "Last",
        email: "email@test.com",
        phone: "555-555-5555"
      }

      arguments = {
        headers: client.headers,
        body: client.contact(**body_args).to_json
      }
      expect(KindfulClient).to receive(:post).with('/imports', arguments).and_return(http_spy)
      user2 = User.new(body_args)
      user2.save
    end
  end
end
