class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  private

  def handle_not_found(exception)
    model_name = exception.model || "Record"
    message = "#{model_name} not found."
    render_error(message, :not_found)
  end

  def render_error(messages, status)
    render json: { errors: Array(messages) }, status: status
  end

  # Default for now is going to be first facility, later on we can change this to any by passing facility id
  # If we switch to search by ID, we will switch status too.
  def find_parking_lot
    @parking_lot ||= ParkingLotFacility.first!
    @parking_lot
  end
end
