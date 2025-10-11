class Ticket < ApplicationRecord
  class BarcodeGenerationError < StandardError; end

  belongs_to :parking_lot_facility

  before_validation :generate_barcode, on: :create
  before_validation :set_issued_at, on: :create

  validates :barcode,
            presence: true,
            uniqueness: true,
            length: { is: 16 },
            format: { with: /\A[0-9A-Fa-f]{16}\z/, message: "must be a 16-character hex string" }

  MAX_BARCODE_GENERATION_ATTEMPTS = 5

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
