module Api
  class TicketsController < ApplicationController
    before_action :find_parking_lot, only: [ :create ]
    before_action :find_ticket, only: [ :show, :state, :update ]

    def create
      price = @parking_lot.prices.last
      if price.nil?
        render_error("No price configured for parking lot", :service_unavailable)
        return
      end

      ticket = @parking_lot.create_ticket_with_lock(price: price)

      if ticket.nil?
        render_error("Parking lot is full", :service_unavailable)
      elsif ticket.persisted?
        render json: {
          barcode: ticket.barcode,
          issued_at: ticket.issued_at
        }, status: :created
      else
        render json: { errors: ticket.errors.full_messages }, status: :unprocessable_content
      end
    rescue Ticket::BarcodeGenerationError => e
      render_error(e.message, :internal_server_error)
    end

    def show
      if @ticket.nil?
        render json: { error: "Ticket not found." }, status: :not_found
        return
      end

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
      if @ticket.nil?
        render json: { error: "Ticket not found." }, status: :not_found
        return
      end

      unless params[:status] == "returned"
        render_error("Invalid status. Only 'returned' is allowed.", :unprocessable_content)
        return
      end

      if @ticket.mark_as_returned!
        render json: {
          barcode: @ticket.barcode,
          status: @ticket.status,
          returned_at: @ticket.returned_at
        }, status: :ok
      else
        render_error("Ticket cannot be returned. Must be paid first.", :unprocessable_content)
      end
    end

    private

    def find_ticket
      barcode = params[:id]
      @ticket = Ticket.find_by!(barcode: barcode)
    end
  end
end
