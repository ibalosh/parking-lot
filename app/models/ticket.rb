class Ticket < ApplicationRecord
  belongs_to :parking_lot_facility
  belongs_to :price_at_entry, class_name: "Price", foreign_key: "price_id"
  has_many :payments

  before_validation :generate_barcode, on: :create
  before_validation :set_issued_at, on: :create

  VALID_STATUSES = %w[active returned]

  validates :barcode,
            presence: true,
            uniqueness: true,
            length: { is: 16 },
            format: { with: /\A[0-9A-Fa-f]{16}\z/, message: "must be a 16-character hex string" }
  validates :issued_at, presence: true
  validates :status, presence: true, inclusion: { in: VALID_STATUSES }

  scope :active, -> { where(status: "active") }

  delegate :currency, to: :price_at_entry

  class BarcodeGenerationError < StandardError; end

  class StatusChangeError < StandardError; end

  MAX_BARCODE_GENERATION_ATTEMPTS = 5

  def can_be_returned?(at_time: Time.current)
    is_paid(at_time: at_time)
  end

  def change_status!(status)
    raise StatusChangeError, "Invalid status. Only 'returned' is allowed." unless VALID_STATUSES.include?(status)

    mark_as_returned!(at_time: Time.current) if status === "returned"
  end

  def mark_as_returned!(at_time: Time.current)
    raise StatusChangeError, "Ticket cannot be returned. Must be paid first." unless can_be_returned?(at_time: at_time)
    return true if status === "returned"

    update!(status: "returned", returned_at: at_time)
    true
  end

  def price_to_pay_at_this_moment
    price_to_pay(at_time: Time.current)
  end

  # Calculate the total price to pay based on parking duration
  # Every started hour costs the price_per_hour from price_at_entry
  # Returns 0 if ticket is already paid
  def price_to_pay(at_time:)
    return 0 if issued_at.nil?
    return 0 if is_paid(at_time: at_time)

    duration_in_seconds = at_time - issued_at
    hours_parked = (duration_in_seconds / 3600.0).ceil # Every started hour

    hours_parked * price_at_entry.price_per_hour
  end

  def price_to_pay_formatted(at_time:)
    "#{price_to_pay(at_time: at_time)} #{currency.symbol}"
  end

  # Get the most recent payment
  def latest_payment
    payments.order(paid_at: :desc).first
  end

  # Check if ticket is paid at a given time
  def is_paid(at_time:)
    payment = latest_payment
    return false unless payment&.paid_at.present?

    time_since_payment = at_time - payment.paid_at
    time_since_payment <= 15.minutes
  end

  def is_paid_formatted(at_time:)
    is_paid(at_time:) ? "paid" : "unpaid"
  end

  private

  def set_issued_at
    self.issued_at ||= Time.current
  end

  def generate_barcode
    self.barcode ||= generate_unique_barcode
  end

  # Generates a 16-hex-digit (64-bit) random barcode with retry-on-collision.
  # A 16-digit hex value provides 2^64 (~1.8e19) possible combinations.
  #
  # Even after generating millions of barcodes, the probability of a collision
  # (birthday paradox ≈ k² / (2 * 2^64)) remains low.
  #
  # The retry loop exists only as a safety net: hitting MAX_BARCODE_GENERATION_ATTEMPTS
  # would require an extremely unlikely sequence of collisions.
  #
  # k = 30*24*365 = 262,800 * 10 = 2,628,000 (30 tickets on average per hour, every day a year for 10 years)
  # N = 18,446,744,073,709,551,616 (2x64)
  # collision probability ≈ k² / (2N) ≈ 0.0000187%
  #
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
