class InventoryPolicy
    def index?
      user.does_inventory?
    end

    def create?
      user.does_inventory?
    end

    def new?
      user.does_inventory?
    end

    def edit?
      user.does_inventory?
    end

    def show?
      user.does_inventory?
    end

    def update?
      user.does_inventory?
    end

    def destroy?
      user.is_admin?
    end

    class Scope
      attr_reader :user, :scope

      def initialize(user, scope)
        @user = user
        @scope = scope
      end
    end
  end

