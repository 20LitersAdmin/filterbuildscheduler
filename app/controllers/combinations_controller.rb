# frozen_string_literal: true

class CombinationsController < ApplicationController
  before_action :set_combination

  def show
    @assemblies = @item.assemblies.ascending

    if @item.is_a? Component
      @all_technologies = @item.all_technologies
      @parents = @item.super_components
    end

    if params[:s].to_i == 1
      @show_sub_assemblies = true
      @toggle_lang = 'Hide sub-assemblies'
      @toggle_link = item_path(@item.uid)
    else
      @show_sub_assemblies = false
      @toggle_lang = 'Show sub-assemblies'
      @toggle_link = item_path(@item.uid, s: 1)
    end

    # YAGNI: Calculates how deep the tree goes, real slow
    # @depth_ary = []
    # @assemblies.component_items.each do |assembly|
    #   downward(assembly)
    # end
    # @depth = @depth_ary.max + 1
  end

  def edit
    @assemblies = @item.assemblies.ascending

    return unless @item.is_a? Component

    @all_technologies = @item.all_technologies
    @parents = @item.super_components
  end

  def price; end

  private

  def set_combination
    @combination = params[:uid].objectify_uid

    return if @combination.present? && [Technology, Component].include?(@combination.class)

    flash[:alert] = 'Please check UID and try again. Must be a Technology or Component'
    # TODO: Where is the best place to return the browser to if the UID fails && reqest.referrer is blank?
    redirect_to request.referrer || rails_admin.dashboard_path
  end
end
