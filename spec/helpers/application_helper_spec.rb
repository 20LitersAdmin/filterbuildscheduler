# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe 'date_for_form' do
    context 'when date is not present' do
      it 'returns today\'s date in iso8601' do
        expect(helper.date_for_form).to eq(Date.today.iso8601)
      end
    end

    context 'when date is present' do
      it 'returns a date in iso8601' do
        date = Date.today - 5.days
        expect(helper.date_for_form(date)).to eq(date.iso8601)
      end
    end
  end

  describe 'human_float' do
    it 'retuns - if nil or zero' do
      expect(helper.human_float(nil)).to eq '-'
      expect(helper.human_float(0.0)).to eq '-'
    end

    it 'returns a float with thousands delimiter' do
      expect(helper.human_float(3456.78)).to eq '3,456.78'
    end
  end

  describe 'human_boolean' do
    it "returns [true: 'Yes', false: 'No']" do
      expect(helper.human_boolean(true)).to eq 'Yes'
      expect(helper.human_boolean(false)).to eq 'No'
    end
  end

  describe 'human_number' do
    it 'returns - if nil or zero' do
      expect(helper.human_number(nil)).to eq '-'
      expect(helper.human_number(0)).to eq '-'
    end

    it 'returns a number with thousands delimiter' do
      expect(helper.human_number(456_789)).to eq '456,789'
    end
  end

  describe 'human_date' do
    it 'returns - if nil' do
      expect(helper.human_date(nil)).to eq '-'
    end

    it 'returns a date formatted mm/dd/yy' do
      expect(helper.human_date(Date.new(2018, 9, 11))).to eq '9/11/18'
    end
  end

  describe 'human_datetime' do
    it 'returns - if nil' do
      expect(helper.human_datetime(nil)).to eq '-'
    end

    it 'returns a time formatted mm/dd/yy HH:MM am/pm' do
      time = Time.new(2021, 9, 14, 13, 30)
      expect(helper.human_datetime(time)).to eq '9/14/21  1:30 pm'

      date = Date.new(2018, 9, 11)
      expect(helper.human_datetime(date)).to eq '9/11/18 12:00 am'
    end
  end

  describe 'human_month_year' do
    it 'returns - if nil' do
      expect(helper.human_month_year(nil)).to eq '-'
    end

    it 'returns a date or time formatted like "Sep, 2019"' do
      date = Date.new(2019, 9, 20)
      expect(helper.human_month_year(date)).to eq 'Sep, 2019'
    end
  end

  describe 'pluralize_without_count' do
    context 'when count is 0' do
      it 'returns nil' do
        expect(helper.pluralize_without_count(0, 'truck')).to eq nil
      end
    end

    context 'when count is 1' do
      it 'returns a singluar noun' do
        expect(helper.pluralize_without_count(1, 'duck')).to eq 'duck'
      end
    end

    context 'when count is not 1 or 0' do
      it 'returns a plural noun' do
        expect(helper.pluralize_without_count(9, 'duck')).to eq 'ducks'
      end
    end
  end

  describe 'time_for_form' do
    it 'returns an iso8601 time' do
      expect(helper.time_for_form('Sun, 07 Jan 2018 00:00:00 EST -05:00')).to eq('2018-01-07T00:00:00-05:00')
    end
  end
end
