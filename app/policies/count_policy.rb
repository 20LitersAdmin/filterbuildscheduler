class CountPolicy
  attr_reader :user, :count

  def initialize(user, count)
    @user = user
    @count = count
  end

  def index?
    user&.does_inventory?
  end

  def create?
    user&.does_inventory?
  end

  def new?
    user&.does_inventory?
  end

  def edit?
    user&.does_inventory?
  end

  def show?
    user&.does_inventory?
  end

  def update?
    user&.does_inventory?
  end

  def destroy?
    user&.is_admin?
  end
end

