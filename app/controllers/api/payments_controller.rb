module Api
  class PaymentsController < ApplicationController
    before_action :find_ticket

    def create
      payment, is_new = @ticket.create_payment_with_lock(
        payment_method: payment_params[:payment_method],
        at_time: Time.current
      )

      status = is_new ? :created : :ok
      render json: payment_json(payment), status: status
    end

    private

    def find_ticket
      barcode = params[:ticket_id]
      @ticket = Ticket.find_by!(barcode: barcode)
    end

    def payment_params
      params.require(:payment).permit(:payment_method, :ticket_id)
    end

    def payment_json(payment)
      {
        barcode: @ticket.barcode,
        amount: "#{payment.amount} #{payment.currency.symbol}",
        payment_method: payment.payment_method,
        paid_at: payment.paid_at
      }
    end
  end
end
