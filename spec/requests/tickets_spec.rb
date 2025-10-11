require 'rails_helper'

RSpec.describe "POST /api/tickets", type: :request do
  context 'when parking lot facility exists' do
    let!(:facility) { create(:parking_lot_facility, spaces_count: 54) }

    it 'creates a new ticket with barcode and issued_at timestamp' do
      expect { post '/api/tickets' }.to change(Ticket, :count).by(1)
      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json['barcode']).to match(/\A[0-9a-f]{16}\z/i)
      expect(Time.parse(json['issued_at'])).to be_within(2.seconds).of(Time.current)
    end

    it 'generates unique barcodes for multiple tickets' do
      post '/api/tickets'
      barcode1 = JSON.parse(response.body)['barcode']

      post '/api/tickets'
      barcode2 = JSON.parse(response.body)['barcode']

      post '/api/tickets'
      barcode3 = JSON.parse(response.body)['barcode']

      expect([ barcode1, barcode2, barcode3 ].uniq.length).to eq(3)
    end

    it 'returns JSON format by default' do
      post '/api/tickets'
      expect(response.content_type).to match(%r{application/json})
    end
  end

  context 'when no parking lot facility exists' do
    it 'returns service unavailable with error message' do
      post '/api/tickets'

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:service_unavailable)
      expect(json['error']).to eq('No parking lot facility available')
    end

    it 'does not create a ticket' do
      expect { post '/api/tickets' }.not_to change(Ticket, :count)
    end
  end
end
