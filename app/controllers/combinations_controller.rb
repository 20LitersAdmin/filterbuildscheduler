# frozen_string_literal: true

class CombinationsController < ApplicationController
  before_action :set_combination, except: :item_search

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

  def price; end

  def item_search
    authorize :combination, :item_search?

    terms = item_search_params[:terms]

    @collection = []

    if terms.length > 3
      # look in Components first (smaller)
      @collection << Component.search_name_and_uid(terms).pluck(:id, :name, :uid)

      # look in Parts second
      @collection << Part.search_name_and_uid(terms)
    end

    respond_to do |format|
      format.json { @collection.flatten.as_json }
    end
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
    params.require(:search).permit(:terms)
  end
end
