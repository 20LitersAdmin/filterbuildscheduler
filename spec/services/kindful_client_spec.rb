require 'rails_helper'

RSpec.describe KindfulClient do
  let(:user1) { build :user }
  let(:client) { KindfulClient.new }

  describe "import_user" do
    fit 'takes user data and sends it to kindful' do
      http_spy = spy
      body_args = {
        id: user1.id,
        fname: user1.fname,
        lname: user1.lname,
        email: user1.email,
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
    fit 'takes data and sends it to kindful' do
      http_spy = spy
      body_args = {
        "first_name": "FNAME",
        "last_name": "LName",
        "email": "foo@bar.com",
        "addr1": "111 West Washington st",
        "addr2": "Unit 2",
        "city": "City",
        "state": "State",
        "postal": "Postal",
        "country": "USA",
        "amount_in_cents": "50000",
        "currency": "usd",
        "campaign": "CauseVox Transactions",
        "fund": "Special Events 40400",
        "acknowledged": "false",
        "transaction_note": "Campaign Name from CauseVox",
        "stripe_charge_id": "ch_1BM3X3Df2Ej1M9QFB2Qmnhwq",
        "transaction_type": "Credit",
        "card_type": "Mastercard",
      }

      arguments = {
        headers: client.headers,
        body: client.contact_w_transaction(body_args).to_json
      }
      expect(KindfulClient).to receive(:post).with('/imports', arguments).and_return(http_spy)
      client.import_transaction(body_args)
    end
  end
end
