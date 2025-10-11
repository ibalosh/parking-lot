FactoryBot.define do
  factory :payment do
    association :ticket
    amount { 2.00 }
    payment_method { "credit_card" }
    paid_at { Time.current }
  end
end
