require 'rails_helper'

RSpec.describe "User management", type: :request do

  describe "with Devise" do
    let(:user) { build :user }

    it "creates a User, signs them in, and redirects to the home page" do
      get new_user_registration_path
      expect(response).to render_template(:new)

      post user_registration_path, params: user.to_json

      expect(response).to redirect_to(assigns(:user))
      follow_redirect!

      expect(response).to render_template("root") 


    end
  end

    
end