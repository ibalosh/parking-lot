class Price < ApplicationRecord
  belongs_to :parking_lot_facility
  belongs_to :currency

  has_many :tickets
end
