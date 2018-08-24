# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Webhooks", type: :request do
  context "successful post from CauseVox" do
    let(:data) { JSON.parse(file_fixture('charge_succeeded_spec.json').read) }

    it "responds with 200 OK" do
      post stripe_webhook_path, params: data
      expect_status :ok
    end

    it "parses the JSON" do
      post stripe_webhook_path, params: data
      expect(assigns(:json)[:metadata][:first_name]).to eq "Julia"
      expect(assigns(:json)[:metadata][:last_name]).to eq "Winter"
      expect(assigns(:json)[:id]).to eq "ch_1BM3X3Df2Ej1M9QFB2Qmnhwq"
      expect(assigns(:json)[:source][:brand]).to eq "Visa"
    end

    it "sends the transaction and user to Kindful" do
      expect_any_instance_of( KindfulClient ).to receive(:import_transaction)
      post stripe_webhook_path, params: data
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
