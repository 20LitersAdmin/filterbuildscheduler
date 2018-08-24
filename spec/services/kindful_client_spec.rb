# frozen_string_literal: true

require 'rails_helper'

RSpec.describe KindfulClient do
  let(:user1) { build :user }
  let(:client) { KindfulClient.new }

  describe "import_user" do
    it 'takes user data and sends it to kindful' do
      http_spy = spy
      body_args = {
        id: user1.id,
        fname: user1.fname,
        lname: user1.lname,
        email: user1.email,
        phone: user1.phone,
        email_opt_in: true
      }

      arguments = {
        headers: client.headers,
        body: client.contact(**body_args).to_json
      }
      expect(KindfulClient).to receive(:post).with('/imports', arguments).and_return(http_spy)
      client.import_user(user1)
    end
  end

  describe "contact_with_transaction" do
    it 'takes data and sends it to kindful' do
      http_spy = spy
      opts= {
        "id": "ch_1BM3X3Df2Ej1M9QFB2Qmnhwq",
        "metadata": {
          "first_name": "FNAME",
          "last_name": "LName",
          "email": "foo@bar.com",
          "line1": "111 West Washington st",
          "line2": "Unit 2",
          "city": "City",
          "state": "State",
          "zipcode": "Postal",
          "country": "USA",
          "campaign_name": "CauseVox Transactions"
        },
        "amount": "50000",
        "source": {
          "brand": "Visa"
        },
      }

      arguments = {
        headers: client.headers,
        body: client.contact_w_transaction(opts).to_json
      }
      expect(KindfulClient).to receive(:post).with('/imports', arguments).and_return(http_spy)
      client.import_transaction(opts)
    end
  end
end
