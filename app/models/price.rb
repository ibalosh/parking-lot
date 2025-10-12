class Price < ApplicationRecord
  has_many :tickets
  belongs_to :parking_lot_facility
  belongs_to :currency

  validates :price_per_hour, presence: true, numericality: { greater_than: 0 }
end
