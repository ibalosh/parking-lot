class PaymentService
  attr_reader :ticket

  def initialize(ticket)
    @ticket = ticket
  end

  # Creates or returns existing payment for a ticket, if already paid.
  #
  # Uses pessimistic locking to prevent race conditions where concurrent payment requests
  # could result in duplicate payments. The lock ensures that the (checking is_paid + creating payment)
  # is atomic across concurrent requests.
  #
  # @param payment_method [String] The payment method ('cash' ...)
  # @param at_time [Time] The timestamp for the payment
  #
  # @return [Array<Payment, Boolean>] A tuple of [payment, is_new] where:
  #   - payment: The created or existing Payment record
  #   - is_new: true if a new payment was created, false if returning existing payment
  #
  # @raise [ActiveRecord::RecordInvalid] If payment validation fails
  def create_payment(payment_method:, at_time: Time.current)
    is_new = false

    payment = Ticket.transaction do
      ticket.lock!

      # Return existing payment if already paid
      if ticket.is_paid(at_time: at_time)
        ticket.latest_payment
      else
        # Create new payment
        is_new = true
        amount = ticket.price_to_pay(at_time: at_time)
        ticket.payments.create!(
          amount: amount,
          payment_method: payment_method,
          paid_at: at_time
        )
      end
    end

    [ payment, is_new ]
  end
end
