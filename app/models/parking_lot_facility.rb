class ParkingLotFacility < ApplicationRecord
  has_many :tickets
  has_many :prices

  validates :name, presence: true, length: { maximum: 255 }
  validates :spaces_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  class ParkingLotFullError < StandardError; end

  def available_spaces
    spaces_count - tickets.active.count
  end

  def full?
    available_spaces <= 0
  end

  # Creates a ticket with pessimistic locking to prevent overbooking.
  #
  # Locks the facility record before checking availability to ensure only one
  # request can check and create a ticket at a time.
  def create_ticket!(price:)
    transaction do
      lock!

      raise ParkingLotFullError, "Parking lot is full" if full?

      tickets.create!(price_at_entry: price)
    end
  end
end
