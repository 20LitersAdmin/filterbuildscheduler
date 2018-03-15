require 'rails_helper'

RSpec.describe Supplier, type: :model do
  let(:supplier) { create :supplier }
  let(:no_url_scheme) { build :supplier, url: "wwww.noscheme.com" }
  let(:no_url_host) { build :supplier, url: "https://" }
  let(:bad_url) { build :supplier, url: "http://www.creeds-blog.blogspot.net.info.biz" }

  describe "must be valid" do
    let(:no_name) { build :supplier, name: nil }
    let(:bad_email) { build :supplier, email: "not an email AT gmail DOT com" }
    let(:bad_poc_email) { build :supplier, poc_email: "heythere.gmail.com" }


    it "in order to save" do
      expect(supplier.save).to eq true
      expect { no_name.save!(validate: false) }.to raise_error ActiveRecord::NotNullViolation
      expect(bad_email.save).to be_falsey
      expect(bad_poc_email.save).to be_falsey
      expect(no_url_scheme.save).to be_falsey
      expect(no_url_host.save).to be_falsey
      expect(bad_url.save).to be_falsey
    end
  end

  describe "#valid_url?" do
    let(:no_url) { create :supplier, url: nil }

    it "allows nil values" do
      expect(no_url.valid_url?).to be true
    end

    it "needs a host" do
      expect(no_url_host.valid_url?).to be_falsey
    end

    it "needs a host with less than 3 periods" do
      expect(bad_url.valid_url?).to be_falsey
    end

    it "needs a valid scheme" do
      expect(no_url_scheme.valid_url?).to be_falsey
    end

  end
end