require 'rails_helper'



RSpec.describe "Stripe Webhook", type: :request do
  context "successful post from CauseVox" do
    before :each do
      data = JSON.parse(file_fixture('charge_succeeded_spec.json').read)
      post stripe_webhook_path, params: data
    end


    fit "responds with 200 OK" do
      expect_status :ok
    end

    fit "parses the JSON" do
      #write this next
      expect( assigns(:json) ).to be  #formatted somehow
      # expect(assigns(:json)[:fname]).to be "the real thing"

    end

    fit "sends the transaction and user to Kindful" do
    end
  end

  context "Post from anyone else" do
    before :each do
      data = { "data": {"object": { "application": "not_causevox" }} }
      post stripe_webhook_path, params: data
    end

    fit "responds with 200 OK" do
      expect_status :ok
    end

    fit "doesn't pass to Kindful" do
      expect_any_instance_of(KindfulClient).to_not receive(:import_transaction)
    end
  end

end