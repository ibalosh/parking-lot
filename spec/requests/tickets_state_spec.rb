require 'rails_helper'

RSpec.describe "GET /api/tickets/{barcode}/state", type: :request do
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
  end

  context 'when ticket does not exist' do
    it 'returns not found error' do
      get "/api/tickets/invalidbarcode123/state"

      expect(response).to have_http_status(:not_found)

      json = JSON.parse(response.body)
      expect(json['errors'][0]).to eq("Ticket not found.")
    end
  end
end
