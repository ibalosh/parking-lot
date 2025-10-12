require 'rails_helper'

RSpec.describe "POST /api/tickets/{barcode}/payments", type: :request do
  let!(:currency) { create(:currency, code: "EUR", symbol: "€") }
  let!(:facility) { create(:parking_lot_facility) }
  let!(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

  context 'when ticket exists' do
    let!(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

    it 'creates a payment with the current amount due' do
      ticket.update_column(:issued_at, 2.5.hours.ago)

      data = { payment: { payment_method: 'credit_card' } }
      expect { post "/api/tickets/#{ticket.barcode}/payments", params: data }.to change(Payment, :count).by(1)

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:created)
      expect(json['barcode']).to eq(ticket.barcode)
      expect(json['amount']).to eq("6.0 €")
      expect(json['payment_method']).to eq('credit_card')
      expect(json['paid_at']).to be_present
    end

    it 'accepts different payment methods' do
      post "/api/tickets/#{ticket.barcode}/payments", params: { payment: { payment_method: 'cash' } }

      expect(response).to have_http_status(:created)

      json = JSON.parse(response.body)
      expect(json['payment_method']).to eq('cash')
    end

    it 'returns existing payment when ticket is already paid' do
      ticket.update_column(:issued_at, 2.hours.ago)
      post "/api/tickets/#{ticket.barcode}/payments", params: { payment: { payment_method: 'credit_card' } }

      expect(response).to have_http_status(:created)
      first_payment = JSON.parse(response.body)

      # Try to pay again - should return existing payment without creating a new one
      expect {
        post "/api/tickets/#{ticket.barcode}/payments", params: { payment: { payment_method: 'cash' } }
      }.not_to change(Payment, :count)

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
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
