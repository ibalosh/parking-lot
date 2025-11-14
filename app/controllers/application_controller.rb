class ApplicationController < ActionController::API
  include ErrorHandler

  private

  # Default for now is going to be the first parking facility. Later on, we can change this to any facility by passing
  # the facility id.
  def find_parking_lot
    @parking_lot ||= ParkingLotFacility.first!
  end
end
