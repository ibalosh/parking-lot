module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_invalid
  end

  def handle_invalid(exception)
    render_error(exception, :unprocessable_content)
  end

  def handle_not_found(exception)
    model_name = exception.model || "Record"
    message = "#{model_name} not found."
    render_error(message, :not_found)
  end

  def render_error(messages, status)
    render json: { errors: Array(messages) }, status: status
  end
end
