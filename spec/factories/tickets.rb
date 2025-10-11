FactoryBot.define do
  factory :ticket do
    association :parking_lot_facility
  end
end
