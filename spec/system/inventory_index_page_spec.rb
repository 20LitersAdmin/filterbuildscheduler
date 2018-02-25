require 'rails_helper'

RSpec.describe "Inventory#index", type: :system do
  before :each do
    
  end

  after :all do
    clean_up!
  end

  context "when visited by" do
    fit "anon users redirects to sign-in page" do
    end

    fit "builders redirects to home page" do
    end

    fit "inventory users shows the page" do
    end

    fit "admins shows the page" do
    end

    fit "users who receive inventory emails shows the page" do
    end
  end

  fit "shows all inventories" do
  end
end