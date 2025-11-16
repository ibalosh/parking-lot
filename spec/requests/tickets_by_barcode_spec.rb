require 'rails_helper'

RSpec.describe "/api/tickets/{barcode}", type: :request do
  describe "PUT /api/tickets/:barcode" do
    let!(:facility) { create(:parking_lot_facility, spaces_count: 54) }
    let!(:price) { create(:price, parking_lot_facility: facility, price_per_hour: 2.00) }

    context 'when ticket exists and is paid' do
      let!(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

      before do
        ticket.update_column(:issued_at, 2.hours.ago)
        ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 5.minutes.ago)
      end

      it 'marks ticket as returned' do
        put "/api/tickets/#{ticket.barcode}", params: { status: 'returned' }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['barcode']).to eq(ticket.barcode)
        expect(json['status']).to eq('returned')
        expect(json['returned_at']).to be_present
      end

      it 'updates the ticket status in database' do
        expect {
          put "/api/tickets/#{ticket.barcode}", params: { status: 'returned' }
        }.to change { ticket.reload.status }.from('active').to('returned')
      end

      it 'sets returned_at timestamp' do
        put "/api/tickets/#{ticket.barcode}", params: { status: 'returned' }

        ticket.reload
        expect(ticket.returned_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'when ticket is not paid' do
      let!(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

      it 'returns unprocessable error' do
        put "/api/tickets/#{ticket.barcode}", params: { status: 'returned' }

        expect(response).to have_http_status(:unprocessable_content)

        json = JSON.parse(response.body)
        expect(json['errors'][0]).to eq('Ticket cannot be returned. Must be paid first.')
      end

      it 'does not update ticket status' do
        expect {
          put "/api/tickets/#{ticket.barcode}", params: { status: 'returned' }
        }.not_to change { ticket.reload.status }
      end
    end

    context 'when ticket payment is expired (over 15 minutes)' do
      let!(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

      before do
        ticket.update_column(:issued_at, 2.hours.ago)
        ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 20.minutes.ago)
      end

      it 'returns unprocessable error' do
        put "/api/tickets/#{ticket.barcode}", params: { status: 'returned' }

        expect(response).to have_http_status(:unprocessable_content)

        json = JSON.parse(response.body)
        expect(json['errors'][0]).to eq('Ticket cannot be returned. Must be paid first.')
      end
    end

    context 'when ticket is already returned' do
      let!(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price, status: 'returned') }

      before do
        ticket.update_column(:issued_at, 2.hours.ago)
        ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 5.minutes.ago)
        ticket.update_column(:returned_at, 2.minutes.ago)
      end

      it 'returns success (idempotent)' do
        put "/api/tickets/#{ticket.barcode}", params: { status: 'returned' }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when status parameter is invalid' do
      let!(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

      it 'returns unprocessable error for invalid status' do
        put "/api/tickets/#{ticket.barcode}", params: { status: 'invalid' }

        expect(response).to have_http_status(:unprocessable_content)

        json = JSON.parse(response.body)
        expect(json['errors'][0]).to eq("Invalid status. Only 'returned' is allowed.")
      end
    end

    context 'when ticket does not exist' do
      it 'returns not found error' do
        put "/api/tickets/invalidbarcode123", params: { status: 'returned' }

        expect(response).to have_http_status(:not_found)

        json = JSON.parse(response.body)
        expect(json['errors'][0]).to eq('Ticket not found.')
      end
    end

    it 'returns JSON format' do
      ticket = create(:ticket, parking_lot_facility: facility, price_at_entry: price)
      ticket.update_column(:issued_at, 2.hours.ago)
      ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 5.minutes.ago)

      put "/api/tickets/#{ticket.barcode}", params: { status: 'returned' }
      expect(response.content_type).to match(%r{application/json})
    end
  end

  describe "GET /api/tickets/:barcode" do
    let!(:currency) { create(:currency, code: "EUR", symbol: "€") }
    let!(:facility) { create(:parking_lot_facility) }
    let!(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

    context 'when ticket exists' do
      let!(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

      it 'returns ticket with calculated price' do
        ticket.update_column(:issued_at, 2.5.hours.ago)

        get "/api/tickets/#{ticket.barcode}"

        json = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)
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
        expect(json['errors'][0]).to eq("Ticket not found.")
      end
    end
  end
end
