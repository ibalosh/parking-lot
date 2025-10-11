class Ticket < ApplicationRecord
  class BarcodeGenerationError < StandardError; end

  belongs_to :parking_lot_facility
  belongs_to :price_at_entry, class_name: "Price", foreign_key: "price_id"

  before_validation :generate_barcode, on: :create
  before_validation :set_issued_at, on: :create

  validates :barcode,
            presence: true,
            uniqueness: true,
            length: { is: 16 },
            format: { with: /\A[0-9A-Fa-f]{16}\z/, message: "must be a 16-character hex string" }

  MAX_BARCODE_GENERATION_ATTEMPTS = 5

  # Calculate the total price to pay based on parking duration
  # Every started hour costs the price_per_hour from price_at_entry
  def price_to_pay
    return 0 if issued_at.nil?

    duration_in_seconds = Time.current - issued_at
    hours_parked = (duration_in_seconds / 3600.0).ceil # Every started hour

    hours_parked * price_at_entry.price_per_hour
  end

  def price_to_pay_formatted
    "#{price_to_pay} #{price_at_entry.currency.symbol}"
  end

  private

  def set_issued_at
    self.issued_at ||= Time.current
  end

  def generate_barcode
    self.barcode ||= generate_unique_barcode
  end

  # Add safety due to possible collision
  # If all {MAX_BARCODE_GENERATION_ATTEMPTS} attempts fail which is
  # extremely unlikely with 16 hex chars = 2^64 possibilities, raises an error
  def generate_unique_barcode
    MAX_BARCODE_GENERATION_ATTEMPTS.times do
      candidate = SecureRandom.hex(8)
      return candidate unless barcode_exists?(candidate)
    end

    raise BarcodeGenerationError, "Failed to generate unique barcode after #{MAX_BARCODE_GENERATION_ATTEMPTS} attempts"
  end

  def barcode_exists?(barcode)
    Ticket.exists?(barcode: barcode)
  end
end
