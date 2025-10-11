module Api
  class TicketsController < ApplicationController
    def create
      # To keep things simple, we will always use the same first parking lot.
      # This allows us though to easily expand to multiple.
      facility = ParkingLotFacility.first

      if facility.nil?
        render json: { error: "No parking lot facility available" }, status: :service_unavailable
        return
      end

      ticket = facility.tickets.build

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
  end
end
