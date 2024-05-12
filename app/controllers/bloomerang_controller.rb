# frozen_string_literal: true

class BloomerangController < ApplicationController
  layout 'blank'

  def import
    authorize :bloomerang, :import?

    BloomerangImportJob.perform_now(total_sync: false)

    flash[:notice] = 'Bloomerang import complete.'
    redirect_to auth_index_path
  end

  def sync
    authorize :bloomerang, :sync?

    BloomerangImportJob.perform_now(total_sync: true)

    flash[:notice] = 'Bloomerang sync complete.'
    redirect_to auth_index_path
  end
end
