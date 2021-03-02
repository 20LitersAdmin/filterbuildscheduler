# frozen_string_literal: true

class PagesController < ApplicationController
  def info
  end

  def route_error
    flash[:danger] = "That's not a real place."
    redirect_to root_path
  end
end
