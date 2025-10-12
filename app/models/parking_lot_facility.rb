class ParkingLotFacility < ApplicationRecord
  has_many :tickets
  has_many :prices

  validates :name, presence: true, length: { maximum: 255 }
  validates :spaces_count, numericality: { only_integer: true, greater_than: 0 }

  def available_spaces
    spaces_count - tickets.active.count
  end

  def full?
    available_spaces <= 0
  end
end
