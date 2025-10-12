module Api
  class TicketsController < ApplicationController
    before_action :find_parking_lot, only: [ :create ]
    before_action :find_ticket, only: [ :show, :state, :update ]

    def create
      price = @parking_lot.prices.last!
      ticket = @parking_lot.create_ticket_with_lock(price: price)

      render json: {
        barcode: ticket.barcode,
        issued_at: ticket.issued_at
      }, status: :created
    rescue ParkingLotFacility::ParkingLotFullError => e
      render_error(e.message, :service_unavailable)
    rescue Ticket::BarcodeGenerationError => e
      render_error(e.message, :internal_server_error)
    end

    def show
      render json: {
        barcode: @ticket.barcode,
        issued_at: @ticket.issued_at,
        price: @ticket.price_to_pay_formatted(at_time: Time.current)
      }, status: :ok
    end

    def state
      render json: {
        barcode: @ticket.barcode,
        state: @ticket.is_paid_formatted(at_time: Time.current)
      }, status: :ok
    end

    def update
      @ticket.change_status!(params_status)

      render json: {
        barcode: @ticket.barcode,
        status: @ticket.status,
        returned_at: @ticket.returned_at
      }, status: :ok

    rescue Ticket::StatusChangeError => e
      render_error(e.message, :unprocessable_content)
    end

    private

    def params_status
      params[:status]
    end

    def find_ticket
      barcode = params[:id]
      @ticket = Ticket.find_by!(barcode: barcode)
    end
  end
end
