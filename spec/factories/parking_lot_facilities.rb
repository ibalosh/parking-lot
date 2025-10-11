FactoryBot.define do
  factory :parking_lot_facility do
    name { Faker::Company.name }
    spaces_count { 54 }
  end
end
