require 'rails_helper'

RSpec.describe "Api::Tickets", type: :request do
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

  describe "GET /api/tickets/:barcode" do
    let!(:currency) { create(:currency, code: "EUR", symbol: "€") }
    let!(:facility) { create(:parking_lot_facility) }
    let!(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

    context 'when ticket exists' do
      let!(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

      it 'returns ticket with calculated price' do
        # Simulate ticket issued 2.5 hours ago (should cost 3 * €2 = €6)
        ticket.update_column(:issued_at, 2.5.hours.ago)

        get "/api/tickets/#{ticket.barcode}"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['barcode']).to eq(ticket.barcode)
        expect(json['issued_at']).to be_present
        expect(json['price']).to eq("6.0 €")
      end

      it 'calculates price for less than 1 hour as 1 hour' do
        ticket.update_column(:issued_at, 30.minutes.ago)

        get "/api/tickets/#{ticket.barcode}"

        json = JSON.parse(response.body)
        expect(json['price']).to eq("2.0 €")
      end

      it 'calculates price for less than 2 hours' do
        ticket.update_column(:issued_at, 90.minutes.ago)

        get "/api/tickets/#{ticket.barcode}"

        json = JSON.parse(response.body)
        expect(json['price']).to eq("4.0 €")
      end

      it 'returns price 0 when ticket is paid' do
        ticket.update_column(:issued_at, 2.hours.ago)
        ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: Time.current)

        get "/api/tickets/#{ticket.barcode}"

        json = JSON.parse(response.body)
        expect(json['price']).to eq("0 €")
      end

      it 'returns JSON format' do
        get "/api/tickets/#{ticket.barcode}"
        expect(response.content_type).to match(%r{application/json})
      end
    end

    context 'when ticket does not exist' do
      it 'returns not found error' do
        get "/api/tickets/invalidbarcode123"

        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json['error']).to eq('Ticket not found')
      end
    end
  end

  describe "POST /api/tickets/:barcode/payments" do
    let!(:currency) { create(:currency, code: "EUR", symbol: "€") }
    let!(:facility) { create(:parking_lot_facility) }
    let!(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

    context 'when ticket exists' do
      let!(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

      it 'creates a payment with the current amount due' do
        ticket.update_column(:issued_at, 2.5.hours.ago)

        expect {
          post "/api/tickets/#{ticket.barcode}/payments", params: { payment: { payment_method: 'credit_card' } }
        }.to change(Payment, :count).by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json['ticket_barcode']).to eq(ticket.barcode)
        expect(json['amount']).to eq("6.0") # 3 hours * €2
        expect(json['payment_method']).to eq('credit_card')
        expect(json['paid_at']).to be_present
      end

      it 'accepts different payment methods' do
        post "/api/tickets/#{ticket.barcode}/payments", params: { payment: { payment_method: 'cash' } }

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json['payment_method']).to eq('cash')
      end

      it 'returns existing payment when ticket is already paid (idempotent)' do
        # Create initial payment
        ticket.update_column(:issued_at, 2.hours.ago)
        post "/api/tickets/#{ticket.barcode}/payments", params: { payment: { payment_method: 'credit_card' } }

        expect(response).to have_http_status(:created)
        first_payment = JSON.parse(response.body)

        # Try to pay again - should return existing payment without creating a new one
        expect {
          post "/api/tickets/#{ticket.barcode}/payments", params: { payment: { payment_method: 'cash' } }
        }.not_to change(Payment, :count)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['amount']).to eq(first_payment['amount'])
        expect(json['payment_method']).to eq('credit_card') # Original payment method
        expect(json['paid_at']).to eq(first_payment['paid_at'])
      end

      it 'returns error for invalid payment method' do
        post "/api/tickets/#{ticket.barcode}/payments", params: { payment: { payment_method: 'bitcoin' } }

        expect(response).to have_http_status(:unprocessable_content)

        json = JSON.parse(response.body)
        expect(json['errors']).to include(/Payment method is not included in the list/)
      end

      it 'returns JSON format' do
        post "/api/tickets/#{ticket.barcode}/payments", params: { payment: { payment_method: 'credit_card' } }
        expect(response.content_type).to match(%r{application/json})
      end
    end

    context 'when ticket does not exist' do
      it 'returns not found error' do
        post "/api/tickets/invalidbarcode123/payments", params: { payment: { payment_method: 'credit_card' } }

        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json['error']).to eq('Ticket not found')
      end
    end
  end

  describe "GET /api/tickets/:barcode/state" do
    let!(:currency) { create(:currency, code: "EUR", symbol: "€") }
    let!(:facility) { create(:parking_lot_facility) }
    let!(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

    context 'when ticket exists' do
      let!(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

      it 'returns unpaid state for ticket without payment' do
        get "/api/tickets/#{ticket.barcode}/state"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['barcode']).to eq(ticket.barcode)
        expect(json['state']).to eq('unpaid')
      end

      it 'returns paid state for ticket with recent payment (within 15 minutes)' do
        ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 10.minutes.ago)

        get "/api/tickets/#{ticket.barcode}/state"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['barcode']).to eq(ticket.barcode)
        expect(json['state']).to eq('paid')
      end

      it 'returns unpaid state for ticket with expired payment (over 15 minutes)' do
        ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 16.minutes.ago)

        get "/api/tickets/#{ticket.barcode}/state"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['barcode']).to eq(ticket.barcode)
        expect(json['state']).to eq('unpaid')
      end

      it 'returns paid state for ticket with payment just under 15 minutes' do
        ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 14.minutes.ago)

        get "/api/tickets/#{ticket.barcode}/state"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['barcode']).to eq(ticket.barcode)
        expect(json['state']).to eq('paid')
      end

      it 'uses the latest payment when multiple payments exist' do
        # Old payment (expired)
        ticket.payments.create!(amount: 2.0, payment_method: 'cash', paid_at: 20.minutes.ago)
        # Recent payment (valid)
        ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 5.minutes.ago)

        get "/api/tickets/#{ticket.barcode}/state"

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['state']).to eq('paid')
      end

      it 'returns JSON format' do
        get "/api/tickets/#{ticket.barcode}/state"
        expect(response.content_type).to match(%r{application/json})
      end
    end

    context 'when ticket does not exist' do
      it 'returns not found error' do
        get "/api/tickets/invalidbarcode123/state"

        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json['error']).to eq('Ticket not found')
      end
    end
  end
end
