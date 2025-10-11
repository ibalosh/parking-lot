class ParkingLotFacility < ApplicationRecord
  has_many :tickets

  validates :name, presence: true, length: { maximum: 255 }
  validates :spaces_count, numericality: { only_integer: true, greater_than: 0 }
end
