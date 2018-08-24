# frozen_string_literal: true

module NotDeleted
  extend ActiveSupport::Concern

  included do
    scope :active, -> { where(deleted_at: nil ) }
  end
end

class Component < ApplicationRecord
  include NotDeleted
end

class Count < ApplicationRecord
  include NotDeleted
end

class Event < ApplicationRecord
  include NotDeleted
end

class Inventory < ApplicationRecord
  include NotDeleted
end

class Location < ApplicationRecord
  include NotDeleted
end

class Material < ApplicationRecord
  include NotDeleted
end

class Part < ApplicationRecord
  include NotDeleted
end

class Registration < ApplicationRecord
  include NotDeleted
end

class Supplier < ApplicationRecord
  include NotDeleted
end

class Technology < ApplicationRecord
  include NotDeleted
end

class User < ApplicationRecord
  include NotDeleted
end
