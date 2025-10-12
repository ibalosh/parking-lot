module Api
  class FreeSpacesController < ApplicationController
    def index
      facility = ParkingLotFacility.first

      if facility.nil?
        render json: { error: "No parking lot facility available" }, status: :service_unavailable
        return
      end

      render json: {
        available_spaces: facility.available_spaces,
        total_spaces: facility.spaces_count
      }, status: :ok
    end
  end
end
