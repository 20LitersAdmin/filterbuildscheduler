require 'rails_helper'

RSpec.describe "Password Reset", type: :system do

  before :each do
    @user = FactoryBot.create(:user)
    visit new_user_password_path
  end

  it "shows a form" do
    expect(page).to have_field "user_email"
    expect(page).to have_button "Send me reset password instructions"
  end

  it "sets a reset_password_token" do

    expect(@user.reset_password_token).to be_nil

    fill_in "user_email", with: @user.email
    click_button "Send me reset password instructions"

    @user.reload
    expect(@user.reset_password_token).not_to be_nil
  end

  it "redirects to sign_in page" do
    fill_in "user_email", with: @user.email
    click_button "Send me reset password instructions"

    expect(page).to have_content "You will receive an email with instructions on how to reset your password in a few minutes."
    expect(page).to have_content "Sign in"
  end

  it "sends an email" do

    @first_count = ActionMailer::Base.deliveries.count

    fill_in "user_email", with: @user.email
    click_button "Send me reset password instructions"
    
    @second_count = ActionMailer::Base.deliveries.count
    @email = ActionMailer::Base.deliveries.last

    expect(@second_count).to eq @first_count + 1

    expect(@email.subject).to eq "[20 Liters] Reset your password"
    expect(@email.to[0]).to eq @user.email
    expect(@email.body.parts.first.body.raw_source).to have_content "Someone has requested a link to change your password"
  end

  fit "honors the reset_password_token" do
    # maybe craft the url with the token?
    # http://localhost:3000/users/password/edit?reset_password_token=sLZNNpmiYa7gD_vykGtN
  end

end