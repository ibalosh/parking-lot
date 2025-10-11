module Api
  class TicketsController < ApplicationController
    before_action :find_facility

    def create
      if @facility.nil?
        render json: { error: "No parking lot facility available" }, status: :service_unavailable
        return
      end

      price = @facility.prices.last
      if price.nil?
        render json: { error: "No price configured for parking lot" }, status: :service_unavailable
        return
      end

      ticket = @facility.tickets.build(price_at_entry: price)

      if ticket.save
        render json: {
          barcode: ticket.barcode,
          issued_at: ticket.issued_at
        }, status: :created
      else
        render json: { errors: ticket.errors.full_messages }, status: :unprocessable_entity
      end
    rescue Ticket::BarcodeGenerationError => e
      render json: { error: e.message }, status: :internal_server_error
    end

    def show
      barcode = params[:id]
      ticket = Ticket.find_by(barcode: barcode)

      if ticket.nil?
        render json: { error: "Ticket not found" }, status: :not_found
        return
      end

      render json: {
        barcode: ticket.barcode,
        issued_at: ticket.issued_at,
        price: ticket.price_to_pay_formatted
      }, status: :ok
    end

    private

    def find_facility
      # To keep things simple, we will always use the same first parking lot.
      # This allows us though to easily expand to multiple.
      #
      # We can easily switch this later to be based on id of the parking lot in API
      @facility = ParkingLotFacility.first
    end
  end
end
