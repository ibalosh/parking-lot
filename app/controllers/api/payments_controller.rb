module Api
  class PaymentsController < ApplicationController
    def create
      # params[:ticket_id] contains the barcode from the URL
      ticket = Ticket.find_by(barcode: params[:ticket_id])

      if ticket.nil?
        render json: { error: "Ticket not found" }, status: :not_found
        return
      end

      # Use pessimistic locking to prevent race conditions on concurrent payment attempts
      Ticket.transaction do
        # Lock the ticket row to prevent concurrent payment creation
        ticket.lock!

        if ticket.is_paid(at_time: Time.current)
          existing_payment = ticket.latest_payment
          render json: {
            barcode: ticket.barcode,
            amount: existing_payment.amount,
            payment_method: existing_payment.payment_method,
            paid_at: existing_payment.paid_at
          }, status: :ok
          return
        end

        amount = ticket.price_to_pay_at_this_moment
        payment = ticket.payments.build(
          amount: amount,
          payment_method: payment_params[:payment_method],
          paid_at: Time.current
        )

        if payment.save
          render json: {
            barcode: ticket.barcode,
            amount: payment.amount,
            payment_method: payment.payment_method,
            paid_at: payment.paid_at
          }, status: :created
        else
          render json: { errors: payment.errors.full_messages }, status: :unprocessable_content
        end
      end
    end

    private

    def payment_params
      params.require(:payment).permit(:payment_method)
    end
  end
end
