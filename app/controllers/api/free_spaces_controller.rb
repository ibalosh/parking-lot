module Api
  class FreeSpacesController < ApplicationController
    before_action :find_parking_lot, only: [ :index ]

    def index
      render json: {
        available_spaces: @parking_lot.available_spaces,
        total_spaces: @parking_lot.spaces_count
      }, status: :ok
    end
  end
end
