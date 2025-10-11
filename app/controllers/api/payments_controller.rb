module Api
  class PaymentsController < ApplicationController
    def create
      # params[:ticket_id] contains the barcode from the URL
      ticket = Ticket.find_by(barcode: params[:ticket_id])

      if ticket.nil?
        render json: { error: "Ticket not found" }, status: :not_found
        return
      end

      amount = ticket.price_to_pay_at_this_moment

      if amount === 0
        render json: { errors: "Ticket is already paid" }, status: :unprocessable_content
      else
        payment = ticket.payments.build(
          amount: amount,
          payment_method: payment_params[:payment_method],
          paid_at: Time.current
        )

        if payment.save
          render json: {
            ticket_barcode: ticket.barcode,
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
