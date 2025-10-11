class Payment < ApplicationRecord
  belongs_to :ticket

  VALID_PAYMENT_METHODS = %w[credit_card debit_card cash].freeze

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_method, presence: true, inclusion: { in: VALID_PAYMENT_METHODS }
  validates :paid_at, presence: true
end
