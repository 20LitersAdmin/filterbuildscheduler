# frozen_string_literal: true

class CombinationsController < ApplicationController
  before_action :set_combination, only: %i[show edit prices]

  def index
    authorize :combination, :index?
    @techs = Technology.kept.list_worthy.order(short_name: :asc)
  end

  def show
    authorize :combination, :show?

    @assemblies = @combination.assemblies.ascending

    if @combination.is_a? Component
      @all_technologies = @combination.all_technologies
      @parents = @combination.super_components
    end

    if params[:s].to_i == 1
      @show_sub_assemblies = true
      @toggle_lang = 'Hide sub-assemblies'
      @toggle_link = combination_path(@combination.uid)
    else
      @show_sub_assemblies = false
      @toggle_lang = 'Show sub-assemblies'
      @toggle_link = combination_path(@combination.uid, s: 1)
    end
  end

  def edit
    authorize :combination, :edit?

    @assemblies = @combination.assemblies.ascending

    return unless @combination.is_a? Component

    @all_technologies = @combination.all_technologies
    @parents = @combination.super_components
  end

  def item_search
    authorize :combination, :item_search?

    # combination can be a Technology or a Component
    @combination = item_search_params[:uid].objectify_uid

    terms = item_search_params[:terms]

    @collection = []

    # prevent the current Component from being returned
    # to prevent an Assembly where the combination and the item are the same thing
    components = @combination.instance_of?(Component) ? Component.kept.where.not(id: @combination.id) : Component.kept

    # look in Components first (smaller)
    @collection << components.search_name_and_uid(terms).order(:uid, :name).pluck(:id, :uid, :name)

    # look in Parts second
    @collection << Part.search_name_and_uid(terms).order(:uid, :name).pluck(:id, :uid, :name)

    render json: @collection.flatten(1)
  end

  private

  def set_combination
    @combination = params[:uid].objectify_uid

    return if @combination.present? && [Technology, Component].include?(@combination.class)

    flash[:alert] = 'Please check UID and try again. Must be a Technology or Component'
    # TODO: Where is the best place to return the browser to if the UID fails && reqest.referrer is blank?
    redirect_to request.referrer || rails_admin.dashboard_path
  end

  def item_search_params
    params.require(:search).permit(:terms, :uid)
  end
end
