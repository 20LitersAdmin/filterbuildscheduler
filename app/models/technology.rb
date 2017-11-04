class Technology < ApplicationRecord
  def qualified_leaders
    User.leaders.where(":id = ANY(qualified_technology_id)", id: id)
  end
end
