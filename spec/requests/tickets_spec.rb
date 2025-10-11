require 'rails_helper'

RSpec.describe "Tickets", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/tickets/create"
      expect(response).to have_http_status(:success)
    end
  end
end
