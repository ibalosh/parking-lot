FactoryBot.define do
  factory :price do
    parking_lot_facility { nil }
    price_per_hour { "9.99" }
    currency { nil }
    valid_from { "2025-10-11" }
  end
end
