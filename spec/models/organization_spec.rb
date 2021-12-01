# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Organization, type: :model do
  let(:organization) { build :organization }

  describe 'must be valid' do
    let(:no_name) { build :organization, company_name: nil }
    let(:no_email) { build :organization, email: nil }

    it 'in order to save' do
      expect(organization.valid?).to eq true
      expect(organization.save).to eq true

      expect(no_name.valid?).to eq false
      expect(no_name.errors.messages[:company_name]).to eq ["can't be blank"]

      expect(no_email.valid?).to eq false
      expect(no_email.errors.messages[:email]).to eq ["can't be blank"]
    end
  end
end
