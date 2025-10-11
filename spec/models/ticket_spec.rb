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
end
