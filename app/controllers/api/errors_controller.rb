module Api
  class ErrorsController < ApplicationController
    def not_found
      render json: { errors: [ "Route not found" ] }, status: :not_found
    end
  end
end
