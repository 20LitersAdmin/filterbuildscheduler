FactoryBot.define do
  factory :inventory do
    manual true
    date Date.today
  end

  factory :inventory_man, class: Inventory do
    manual true
    date Date.today
  end

  factory :inventory_ship, class: Inventory do
    shipping true
    date Date.today
  end

  factory :inventory_rec, class: Inventory do
    receiving true
    date Date.today
  end

  factory :inventory_event, class: Inventory do
    event
    date Date.today
  end
end