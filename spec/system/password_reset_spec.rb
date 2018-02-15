require 'rails_helper'

RSpec.describe "Password Reset", type: :system do

  it "shows a form" do
  end

  it "sets a reset_password_token" do
  end

  it "redirects to sign_in page" do
    # expect(page).to have_content "You will receive an email with instructions on how to reset your password in a few minutes."
  end

  it "sends an email" do
    # http://guides.rubyonrails.org/testing.html#testing-your-mailers
  end

  it "honors the reset_password_token" do
    # maybe craft the url with the token?
    # http://localhost:3000/users/password/edit?reset_password_token=sLZNNpmiYa7gD_vykGtN
  end

end