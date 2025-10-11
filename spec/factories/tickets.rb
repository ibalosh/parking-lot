FactoryBot.define do
  factory :ticket do
    barcode { "MyString" }
    parking_lot_facility { nil }
  end
end
