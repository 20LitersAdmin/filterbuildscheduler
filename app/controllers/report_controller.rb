# frozen_string_literal: true

class ReportController < ApplicationController
  def index
  end

  def volunteers
    start_year = Date.today.month >= 7 ? Date.today.year - 1 : Date.today.year
    @start_date = params[:start].present? ? params[:start].to_date : Date.new(start_year, 7, 1)
    @end_date = params[:end].present? ? params[:end].to_date : Date.new(start_year + 1, 6, 30)

    @events = Event.where(end_time: @start_date..@end_date).order(start_time: :asc)

    @registrations = Registration.attended.where(event_id: @events.map(&:id))

    @leaders = User.where(id: @registrations.leaders.map(&:user_id)).order(lname: :asc, fname: :asc)
    @all_builders = User.where(id: @registrations.builders.map(&:user_id)).order(lname: :asc, fname: :asc)
    all_builder_ids = @registrations.builders.map(&:user_id)
    return_builder_ids = all_builder_ids.select { |e| all_builder_ids.count(e) > 1 }.uniq
    @return_builders = User.where(id: return_builder_ids).order(lname: :asc, fname: :asc)
  end

  def leaders
    start_year = Date.today.month >= 7 ? Date.today.year - 1 : Date.today.year
    @start_date = params[:start].present? ? params[:start].to_date : Date.new(start_year, 7, 1)
    @end_date = params[:end].present? ? params[:end].to_date : Date.new(start_year + 1, 6, 30)

    @events = Event.where(end_time: @start_date..@end_date).order(start_time: :asc)

    @registrations = Registration.attended.where(event_id: @events.map(&:id))

    @active_leaders = User.where(id: @registrations.leaders.map(&:user_id)).order(lname: :asc, fname: :asc)
    @inactive_leaders = User.leaders.where.not(id: @registrations.leaders.map(&:user_id)).order(lname: :asc, fname: :asc)
  end
end
