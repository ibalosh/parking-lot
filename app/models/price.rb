class Price < ApplicationRecord
  has_one :ticket
  belongs_to :parking_lot_facility
  belongs_to :currency

  validates :price_per_hour, presence: true, numericality: { greater_than: 0 }
end
