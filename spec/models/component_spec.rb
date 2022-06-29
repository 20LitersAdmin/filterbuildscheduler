# frozen_string_literal: true

require 'rails_helper'
require 'concerns/itemable'

RSpec.describe Component, type: :model do
  it_behaves_like Itemable

  let(:component) { create :component }

  describe 'must be valid' do
    let(:no_name) { build :component, name: nil }
    let(:negative_price) { build :component, price_cents: -560 }

    it 'in order to save' do
      expect(component.save).to eq true
      expect { no_name.save!(validate: false) }
        .to raise_error ActiveRecord::NotNullViolation
    end

    it 'prices must be positive' do
      expect(negative_price.save).to be_falsey
      expect(negative_price.errors.messages[:price]).to eq ['must be greater than or equal to 0']
    end
  end

  describe 'Component#search_name_and_uid(string)' do
    context 'when string is blank' do
      it 'returns Component.none' do
        expect(Component.search_name_and_uid('')).to eq Component.none
      end
    end

    context 'when string is not a String' do
      it 'returns Component.none' do
        expect(Component.search_name_and_uid(256)).to eq Component.none
        expect(Component.search_name_and_uid(%w[ary with items])).to eq Component.none
        expect(Component.search_name_and_uid(true)).to eq Component.none
      end
    end

    context 'when string is a String' do
      let(:blue_comp) { create :component, name: 'blue component' }
      let(:red_comp) { create :component, name: 'thing that is red' }
      let(:green_comp) { create :component, name: 'green object' }
      let(:uid_comp) { create :component }

      it 'performs an SQL ILIKE any match against :uid and :name' do
        blue_comp
        red_comp
        green_comp
        string = "blue red #{uid_comp.uid}"

        expect(Component.search_name_and_uid(string)).to include blue_comp
        expect(Component.search_name_and_uid(string)).to include red_comp
        expect(Component.search_name_and_uid(string)).not_to include green_comp
        expect(Component.search_name_and_uid(string)).to include uid_comp
      end
    end
  end

  describe '#super_components' do
    let(:super_comp) { create :component, name: 'super component' }
    let(:super_assembly) { create :assembly, combination: super_comp, item: component }
    let(:sub_comp) { create :component }
    let(:sub_assembly) { create :assembly, combination: component, item: sub_comp }

    it 'returns a collection of Components that depend on this component' do
      super_assembly
      sub_assembly

      expect(component.super_components).to include super_comp
      expect(component.super_components).not_to include sub_comp
    end
  end

  describe '#sub_components' do
    let(:super_comp) { create :component, name: 'super component' }
    let(:super_assembly) { create :assembly, combination: super_comp, item: component }
    let(:sub_comp) { create :component }
    let(:sub_assembly) { create :assembly, combination: component, item: sub_comp }

    it 'returns a collection of Components that this component depends on' do
      super_assembly
      sub_assembly

      expect(component.sub_components).not_to include super_comp
      expect(component.sub_components).to include sub_comp
    end
  end

  describe '#uid_and_name' do
    it 'returns a string' do
      expect(component.uid_and_name.class).to eq String
    end
  end

  describe '#dependent_destroy_assemblies' do
    let(:super_comp) { create :component, name: 'super component' }
    let(:super_assembly) { create :assembly, combination: super_comp, item: component }
    let(:sub_comp) { create :component }
    let(:sub_assembly) { create :assembly, combination: component, item: sub_comp }

    it 'fires on before_destroy' do
      expect(component).to receive(:dependent_destroy_assemblies)

      component.destroy
    end

    it 'destroys all associated assemblies, up and down' do
      super_assembly
      sub_assembly

      component.__send__(:dependent_destroy_assemblies)

      expect { super_assembly.reload }
        .to raise_error ActiveRecord::RecordNotFound

      expect { sub_assembly.reload }
        .to raise_error ActiveRecord::RecordNotFound
    end
  end
end
