# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Part, type: :model do
  let(:part) { create :part }

  describe 'must be valid' do
    let(:no_name) { build :part, name: nil }
    let(:no_price) { build :part, price_cents: nil }
    let(:no_minimum) { build :part, minimum_on_hand: nil }

    let(:negative_price) { build :part, price_cents: -299 }

    it 'in order to save' do
      expect(part.save).to eq true

      expect { no_name.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_price.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
      expect { no_minimum.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
    end

    it 'prices can\'t be negative' do
      expect(negative_price.save).to be_falsey
    end
  end


end
