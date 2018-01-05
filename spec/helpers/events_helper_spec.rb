require 'rails_helper'

RSpec.describe EventsHelper, type: :helper do
  describe "time_for_form" do
    it "formats a time compatible with the event _form" do
      expect(helper.time_for_form("Sun, 07 Jan 2018 00:00:00 EST -05:00 ")).to eq("2018-01-07T00:00:00-05:00")
    end
  end
end