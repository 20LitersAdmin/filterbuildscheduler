require 'rails_helper'

RSpec.describe EventsController, type: :controller do

  describe "GET Index" do
    let(:future_event) { create :event, start_time: Time.now + 4.days, end_time: Time.now + 4.days + 2.hours }
    let(:private_event) { create :event, start_time: Time.now + 4.days, end_time: Time.now + 4.days + 2.hours, is_private: true }

    let(:past_event) { create :event, start_time: Time.now - 4.days, end_time: Time.now - 4.days + 2.hours }
    let(:deleted_event) { create :event, created_at: Time.now - 3.days, deleted_at: Time.now - 2.days }

    let(:registered_event) { create :event, start_time: Time.now + 4.days, end_time: Time.now + 4.days + 2.hours }
    let(:user) { create :user }
    let(:registration) { create :registration, user: user, event: registered_event }

    before(:each) do
      get :index
    end
    
    describe "when there's no current_user" do
      # don't login_admin or login_user

      fit "shows only future events" do
        expect(subject.current_user).to eq nil

        expect(assigns(:events)).to include(future_event, registered_event)
        expect(assigns(:events)).not_to include(past_event, private_event)
        expect(assigns(:cancelled_events).count).to eq 0
      end
    end

    describe "when the current_user is an admin" do
      login_admin


      fit "show all types of events" do
        future_event
        past_event
        private_event
        deleted_event
        registered_event
        user
        registration

        expect(subject.current_user.is_admin?).to be true

        binding.pry
        expect(assigns(:events)).to include(future_event, private_event, registered_event)
        expect(assigns(:past_events)).to include(past_event)
        expect(assigns(:cancelled_events).count).to eq 1
      end
    end

    describe "when the current_user is not an admin" do
      login_user

      it "shows public, future events" do
        expect(subject.current_user).to_not eq nil
        expect(subject.current_user.is_admin?).to eq false
      end
    end

  end
end
