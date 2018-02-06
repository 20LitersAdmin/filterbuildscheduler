require 'rails_helper'

RSpec.describe Supplier, type: :model do
  let(:supplier) { create :supplier }

  describe "must be valid" do
    let(:no_name) { build :supplier, name: nil }
    let(:bad_email) { build :supplier, email: "not an email AT gmail DOT com" }
    let(:bad_POC_email) { build :supplier, POC_email: "heythere.gmail.com" }
    let(:no_url_scheme) { build :supplier, url: "wwww.noscheme.com" }
    let(:no_url_host) { build :supplier, url: "https://" }
    let(:bad_url) { build :supplier, url: "http://www.creeds-blog.blogspot.net.info.biz" }


    it "in order to save" do
      expect(supplier.save).to eq true
      expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect(bad_email.save).to be_falsey
      expect(bad_POC_email.save).to be_falsey
      expect(no_url_scheme.save).to be_falsey
      expect(no_url_host.save).to be_falsey
      expect(bad_url.save).to be_falsey
    end
  end
end