# frozen_string_literal: true

class BloomerangPolicy < ApplicationPolicy
  def import?
    user&.is_oauth_admin?
  end

  def sync?
    import?
  end
end
