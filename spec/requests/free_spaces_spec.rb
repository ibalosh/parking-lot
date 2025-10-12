require 'rails_helper'

RSpec.describe "Api::FreeSpaces", type: :request do
  describe "GET /api/free-spaces" do
    context 'when parking lot facility exists' do
      let!(:currency) { create(:currency) }
      let!(:facility) { create(:parking_lot_facility, spaces_count: 54) }
      let!(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

      context 'when no tickets exist' do
        it 'returns all spaces as available' do
          get '/api/free-spaces'

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          expect(json['available_spaces']).to eq(54)
          expect(json['total_spaces']).to eq(54)
        end
      end

      context 'when some active tickets exist' do
        before do
          create_list(:ticket, 10, parking_lot_facility: facility, price_at_entry: price, status: 'active')
        end

        it 'returns available spaces minus active tickets' do
          get '/api/free-spaces'

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          expect(json['available_spaces']).to eq(44)
          expect(json['total_spaces']).to eq(54)
        end
      end

      context 'when returned tickets exist' do
        before do
          create_list(:ticket, 5, parking_lot_facility: facility, price_at_entry: price, status: 'returned')
        end

        it 'does not count returned tickets as occupying space' do
          get '/api/free-spaces'

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          expect(json['available_spaces']).to eq(54)
          expect(json['total_spaces']).to eq(54)
        end
      end

      context 'when both active and returned tickets exist' do
        before do
          create_list(:ticket, 20, parking_lot_facility: facility, price_at_entry: price, status: 'active')
          create_list(:ticket, 15, parking_lot_facility: facility, price_at_entry: price, status: 'returned')
        end

        it 'only counts active tickets' do
          get '/api/free-spaces'

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          expect(json['available_spaces']).to eq(34)
          expect(json['total_spaces']).to eq(54)
        end
      end

      context 'when parking lot is full' do
        before do
          create_list(:ticket, 54, parking_lot_facility: facility, price_at_entry: price, status: 'active')
        end

        it 'returns 0 available spaces' do
          get '/api/free-spaces'

          expect(response).to have_http_status(:ok)

          json = JSON.parse(response.body)
          expect(json['available_spaces']).to eq(0)
          expect(json['total_spaces']).to eq(54)
        end
      end

      it 'returns JSON format' do
        get '/api/free-spaces'
        expect(response.content_type).to match(%r{application/json})
      end
    end

    context 'when no parking lot facility exists' do
      it 'returns service unavailable error' do
        get '/api/free-spaces'

        expect(response).to have_http_status(:service_unavailable)

        json = JSON.parse(response.body)
        expect(json['error']).to eq('No parking lot facility available')
      end
    end
  end
end
