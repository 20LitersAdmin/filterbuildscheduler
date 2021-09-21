# frozen_string_literal: true

class AssembliesController < ApplicationController
  before_action :authorize_assembly
  before_action :set_item_from_uid, except: %i[index]

  def index
    # show all assembly records in some meaningful way?
    # since we aren't in RailsAdmin
  end

  def show
    @assemblies = @item.assemblies.ascending
  end

  def items
  end

  def price
  end

  private

  def authorize_assembly
    authorize Assembly
  end

  def set_item_from_uid
    # we're mimicing the standard structure, but
    # we're actually passing the `:uid` in place of the `:id`
    # so we can objectify the string to get the @item
    @item = params[:id].objectify_uid

    return if @item.present? && [Technology, Component].include?(@item.class)

    flash[:alert] = 'Please check UID and try again. Must be a Technology or Component'
    # TODO: Where is the best place to return the browser to if the UID fails && reqest.referrer is blank?
    redirect_to request.referrer || rails_admin.dashboard_path
  end
end
