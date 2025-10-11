require 'rails_helper'

RSpec.describe Ticket, type: :model do
  let(:facility) { create(:parking_lot_facility) }

  describe 'ticket creation' do
    it 'automatically generates a unique 16-character hex barcode' do
      ticket = facility.tickets.create!

      expect(ticket.barcode).to be_present
      expect(ticket.barcode).to match(/\A[0-9a-f]{16}\z/i)
      expect(ticket.barcode.length).to eq(16)
    end

    it 'automatically sets issued_at timestamp' do
      ticket = facility.tickets.create!

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
end
