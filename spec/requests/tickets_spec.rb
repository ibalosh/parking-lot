require 'rails_helper'

RSpec.describe "api/tickets", type: :request do
  describe "POST /api/tickets" do
    context 'when parking lot facility exists with price' do
      let!(:currency) { create(:currency) }
      let!(:facility) { create(:parking_lot_facility, spaces_count: 54) }
      let!(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

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

    context 'when facility exists but no price is configured' do
      let!(:facility) { create(:parking_lot_facility) }

      it 'returns service unavailable with error message' do
        post '/api/tickets'

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:service_unavailable)
        expect(json['error']).to eq('No price configured for parking lot')
      end
    end
  end

  describe "POST /api/tickets when parking lot is full" do
    let!(:currency) { create(:currency) }
    let!(:facility) { create(:parking_lot_facility, spaces_count: 54) }
    let!(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

    context 'when parking lot has exactly 54 active tickets' do
      before do
        create_list(:ticket, 54, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      end

      it 'returns service unavailable error' do
        post '/api/tickets'

        expect(response).to have_http_status(:service_unavailable)

        json = JSON.parse(response.body)
        expect(json['error']).to eq('Parking lot is full')
      end

      it 'does not create a new ticket' do
        expect { post '/api/tickets' }.not_to change(Ticket, :count)
      end
    end

    context 'when parking lot has 53 active tickets (1 space left)' do
      before do
        create_list(:ticket, 53, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      end

      it 'allows creating a ticket' do
        expect { post '/api/tickets' }.to change(Ticket, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context 'when parking lot has returned tickets' do
      before do
        create_list(:ticket, 54, parking_lot_facility: facility, price_at_entry: price, status: 'returned')
      end

      it 'allows creating new tickets (returned tickets free up space)' do
        expect { post '/api/tickets' }.to change(Ticket, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context 'when parking lot has mix of active and returned tickets' do
      before do
        create_list(:ticket, 50, parking_lot_facility: facility, price_at_entry: price, status: 'active')
        create_list(:ticket, 10, parking_lot_facility: facility, price_at_entry: price, status: 'returned')
      end

      it 'allows creating tickets up to limit' do
        # Should be able to create 4 more tickets (54 - 50 = 4)
        expect { post '/api/tickets' }.to change(Ticket, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end
  end
end
