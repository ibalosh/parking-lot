FactoryBot.define do
  factory :ticket do
    association :parking_lot_facility
    association :price_at_entry, factory: :price
  end
end
