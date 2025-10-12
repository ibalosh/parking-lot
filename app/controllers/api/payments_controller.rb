module Api
  class PaymentsController < ApplicationController
    before_action :find_ticket

    def create
      # Use pessimistic locking to prevent race conditions on concurrent payment attempts
      Ticket.transaction do
        # Lock the ticket row to prevent concurrent payment creation
        @ticket.lock!

        if @ticket.is_paid(at_time: Time.current)
          payment = @ticket.latest_payment
          render json: {
            barcode: @ticket.barcode,
            amount: "#{payment.amount} #{payment.currency.symbol}",
            payment_method: payment.payment_method,
            paid_at: payment.paid_at
          }, status: :ok
          return
        end

        amount = @ticket.price_to_pay_at_this_moment
        payment = @ticket.payments.build(
          amount: amount,
          payment_method: payment_params[:payment_method],
          paid_at: Time.current
        )

        if payment.save
          render json: {
            barcode: @ticket.barcode,
            amount: "#{payment.amount} #{payment.currency.symbol}",
            payment_method: payment.payment_method,
            paid_at: payment.paid_at
          }, status: :created
        else
          render json: { errors: payment.errors.full_messages }, status: :unprocessable_content
        end
      end
    end

    private

    def find_ticket
      barcode = params[:ticket_id]
      @ticket = Ticket.find_by!(barcode: barcode)
    end

    def payment_params
      params.require(:payment).permit(:payment_method, :ticket_id)
    end
  end
end
