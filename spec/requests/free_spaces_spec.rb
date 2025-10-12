require 'rails_helper'

RSpec.describe "/api/free-spaces", type: :request do
  describe "GET /api/free-spaces" do
    let!(:currency) { create(:currency) }
    let!(:facility) { create(:parking_lot_facility, spaces_count: 54) }
    let!(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

    it 'returns all spaces as available when no tickets exist' do
      get '/api/free-spaces'

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json['available_spaces']).to eq(54)
      expect(json['total_spaces']).to eq(54)
    end

    it 'returns available spaces minus active tickets' do
      create_list(:ticket, 10, parking_lot_facility: facility, price_at_entry: price, status: 'active')

      get '/api/free-spaces'

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json['available_spaces']).to eq(44)
      expect(json['total_spaces']).to eq(54)
    end

    it 'does not count returned tickets as occupying space' do
      create_list(:ticket, 5, parking_lot_facility: facility, price_at_entry: price, status: 'returned')

      get '/api/free-spaces'

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json['available_spaces']).to eq(54)
      expect(json['total_spaces']).to eq(54)
    end

    it 'only counts active tickets when both active and returned exist' do
      create_list(:ticket, 20, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      create_list(:ticket, 15, parking_lot_facility: facility, price_at_entry: price, status: 'returned')

      get '/api/free-spaces'

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json['available_spaces']).to eq(34)
      expect(json['total_spaces']).to eq(54)
    end

    it 'returns 0 available spaces when parking lot is full' do
      create_list(:ticket, 54, parking_lot_facility: facility, price_at_entry: price, status: 'active')

      get '/api/free-spaces'

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json['available_spaces']).to eq(0)
      expect(json['total_spaces']).to eq(54)
    end

    it 'returns JSON format' do
      get '/api/free-spaces'
      expect(response.content_type).to match(%r{application/json})
    end
  end

  describe "GET /api/free-spaces when no facility exists" do
    it 'returns service unavailable error' do
      get '/api/free-spaces'

      expect(response).to have_http_status(:not_found)

      json = JSON.parse(response.body)
      expect(json['errors'][0]).to eq("Couldn't find ParkingLotFacility")
    end
  end
end
