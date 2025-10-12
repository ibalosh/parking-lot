class ParkingLotFacility < ApplicationRecord
  has_many :tickets
  has_many :prices

  validates :name, presence: true, length: { maximum: 255 }
  validates :spaces_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def available_spaces
    spaces_count - tickets.active.count
  end

  def full?
    available_spaces <= 0
  end

  def create_ticket_with_lock(price:)
    transaction do
      lock!

      return nil if full?

      tickets.create!(price_at_entry: price)
    end
  end
end
