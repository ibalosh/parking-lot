require 'rails_helper'

RSpec.describe Ticket, type: :model do
  let(:currency) { create(:currency) }
  let(:facility) { create(:parking_lot_facility) }
  let(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

  describe 'ticket creation' do
    it 'automatically generates a unique 16-character hex barcode' do
      ticket = facility.tickets.create!(price_at_entry: price)

      expect(ticket.barcode).to be_present
      expect(ticket.barcode).to match(/\A[0-9a-f]{16}\z/i)
      expect(ticket.barcode.length).to eq(16)
    end

    it 'automatically sets issued_at timestamp' do
      ticket = facility.tickets.create!(price_at_entry: price)

      expect(ticket.issued_at).to be_present
      expect(ticket.issued_at).to be_within(1.second).of(Time.current)
    end

    it 'enforces barcode uniqueness' do
      ticket1 = create(:ticket)
      ticket2 = build(:ticket, barcode: ticket1.barcode)

      expect(ticket2).not_to be_valid
      expect(ticket2.errors[:barcode]).to be_present
    end
  end

  describe '#price_to_pay' do
    let(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }
    let(:entry_time) { Time.parse("2025-10-11 10:00:00") }

    before do
      ticket.update_column(:issued_at, entry_time)
    end

    it 'calculates price for partial hour as full hour' do
      at_time = entry_time + 30.minutes
      expect(ticket.price_to_pay(at_time:)).to eq(2.0)
    end

    it 'calculates price for exactly 1 hour' do
      at_time = entry_time + 1.hour
      expect(ticket.price_to_pay(at_time:)).to eq(2.0)
    end

    it 'calculates price for slightly over 1 hour' do
      at_time = entry_time + 1.hour + 30.seconds
      expect(ticket.price_to_pay(at_time:)).to eq(4.0)
    end

    it 'calculates price for 2.5 hours as 3 hours' do
      at_time = entry_time + 2.5.hours
      expect(ticket.price_to_pay(at_time:)).to eq(6.0)
    end

    it 'calculates price for multiple full hours' do
      at_time = entry_time + 5.hours
      expect(ticket.price_to_pay(at_time:)).to eq(10.0)
    end
  end

  describe '#price_to_pay_formatted' do
    let(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }
    let(:entry_time) { Time.parse("2025-10-11 10:00:00") }

    it 'returns formatted price with currency symbol' do
      ticket.update_column(:issued_at, entry_time)
      at_time = entry_time + 1.hour
      expect(ticket.price_to_pay_formatted(at_time:)).to eq("2.0 €")
    end
  end

  describe 'status field' do
    it 'defaults to active when ticket is created' do
      ticket = create(:ticket, parking_lot_facility: facility, price_at_entry: price)
      expect(ticket.status).to eq('active')
    end

    it 'validates status is either active or returned' do
      ticket = build(:ticket, parking_lot_facility: facility, price_at_entry: price, status: 'invalid')
      expect(ticket).not_to be_valid
      expect(ticket.errors[:status]).to be_present
    end

    it 'allows active status' do
      ticket = build(:ticket, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      expect(ticket).to be_valid
    end

    it 'allows returned status' do
      ticket = build(:ticket, parking_lot_facility: facility, price_at_entry: price, status: 'returned')
      expect(ticket).to be_valid
    end
  end

  describe '.active scope' do
    it 'returns only active tickets' do
      active_ticket1 = create(:ticket, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      active_ticket2 = create(:ticket, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      returned_ticket = create(:ticket, parking_lot_facility: facility, price_at_entry: price, status: 'returned')

      expect(Ticket.active).to include(active_ticket1, active_ticket2)
      expect(Ticket.active).not_to include(returned_ticket)
    end
  end

  describe '#can_be_returned?' do
    let(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

    it 'returns true when ticket is paid and within 15 minutes' do
      ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 10.minutes.ago)
      expect(ticket.can_be_returned?).to be true
    end

    it 'returns false when ticket is not paid' do
      expect(ticket.can_be_returned?).to be false
    end

    it 'returns false when ticket is paid but over 15 minutes ago' do
      ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 16.minutes.ago)
      expect(ticket.can_be_returned?).to be false
    end
  end

  describe '#mark_as_returned!' do
    let(:ticket) { create(:ticket, parking_lot_facility: facility, price_at_entry: price) }

    it 'updates status to returned when ticket is paid' do
      ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 5.minutes.ago)

      expect {
        ticket.mark_as_returned!
      }.to change { ticket.status }.from('active').to('returned')
    end

    it 'sets returned_at timestamp when ticket is paid' do
      ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 5.minutes.ago)
      ticket.mark_as_returned!

      expect(ticket.returned_at).to be_within(1.second).of(Time.current)
    end

    it 'returns true when ticket can be returned' do
      ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 5.minutes.ago)
      expect(ticket.mark_as_returned!).to be true
    end

    it 'does not update status when ticket is not paid' do
      expect { ticket.mark_as_returned! }.not_to change { ticket.status }
    end

    it 'does not set returned_at when ticket is not paid' do
      ticket.mark_as_returned!
      expect(ticket.returned_at).to be_nil
    end

    it 'returns false when ticket cannot be returned' do
      expect(ticket.mark_as_returned!).to be false
    end

    it 'returns true when ticket is already returned (idempotent)' do
      ticket.payments.create!(amount: 4.0, payment_method: 'credit_card', paid_at: 5.minutes.ago)
      ticket.mark_as_returned!

      expect(ticket.mark_as_returned!).to be true
    end
  end
end
