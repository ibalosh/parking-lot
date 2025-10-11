FactoryBot.define do
  factory :price do
    association :parking_lot_facility
    association :currency
    price_per_hour { 2.00 }
  end
end
