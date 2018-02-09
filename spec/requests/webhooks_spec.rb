require 'rails_helper'

RSpec.describe "Webhooks", type: :request do
  context "successful post from CauseVox" do
    before :each do
      @data = JSON.parse(file_fixture('charge_succeeded_spec.json').read)
      post stripe_webhook_path, params: @data
      @client = KindfulClient.new
    end

    it "responds with 200 OK" do
      expect_status :ok
    end

    it "parses the JSON" do
      expect(assigns(:json)[:metadata][:first_name]).to eq "Julia"
      expect(assigns(:json)[:metadata][:last_name]).to eq "Winter"
      expect(assigns(:json)[:id]).to eq "ch_1BM3X3Df2Ej1M9QFB2Qmnhwq"
      expect(assigns(:json)[:source][:brand]).to eq "Visa"
    end

    it "sends the transaction and user to Kindful" do
      pending("Ross, huh?!? I don't understand receive.")
      expect( KindfulClient ).to receive(:import_transaction).with(@data)
      @client.import_transaction(@data)
    end
  end

  context "Post from anyone else" do
    before :each do
      data = { "data": {"object": { "application": "not_causevox" }} }
      post stripe_webhook_path, params: data
    end

    it "responds with 200 OK" do
      expect_status :ok
    end

    it "doesn't pass to Kindful" do
      expect_any_instance_of(KindfulClient).to_not receive(:import_transaction)
    end
  end

end