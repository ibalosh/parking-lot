require 'rails_helper'

RSpec.describe ParkingLotFacility, type: :model do
  let(:currency) { create(:currency) }
  let(:facility) { create(:parking_lot_facility, spaces_count: 54) }
  let(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

  describe '#available_spaces' do
    context 'when no tickets exist' do
      it 'returns total spaces count' do
        expect(facility.available_spaces).to eq(54)
      end
    end

    context 'when some active tickets exist' do
      it 'returns spaces count minus active tickets' do
        create_list(:ticket, 3, parking_lot_facility: facility, price_at_entry: price, status: 'active')
        expect(facility.available_spaces).to eq(51)
      end
    end

    context 'when returned tickets exist' do
      it 'does not count returned tickets' do
        create_list(:ticket, 5, parking_lot_facility: facility, price_at_entry: price, status: 'returned')
        expect(facility.available_spaces).to eq(54)
      end
    end

    context 'when both active and returned tickets exist' do
      it 'only counts active tickets' do
        create_list(:ticket, 10, parking_lot_facility: facility, price_at_entry: price, status: 'active')
        create_list(:ticket, 5, parking_lot_facility: facility, price_at_entry: price, status: 'returned')
        expect(facility.available_spaces).to eq(44)
      end
    end

    context 'when parking lot is full' do
      it 'returns 0' do
        create_list(:ticket, 54, parking_lot_facility: facility, price_at_entry: price, status: 'active')
        expect(facility.available_spaces).to eq(0)
      end
    end
  end

  describe '#full?' do
    context 'when spaces are available' do
      it 'returns false' do
        create_list(:ticket, 10, parking_lot_facility: facility, price_at_entry: price, status: 'active')
        expect(facility.full?).to be false
      end
    end

    context 'when parking lot is exactly full' do
      it 'returns true' do
        create_list(:ticket, 54, parking_lot_facility: facility, price_at_entry: price, status: 'active')
        expect(facility.full?).to be true
      end
    end

    context 'when no tickets exist' do
      it 'returns false' do
        expect(facility.full?).to be false
      end
    end

    context 'when one space remains' do
      it 'returns false' do
        create_list(:ticket, 53, parking_lot_facility: facility, price_at_entry: price, status: 'active')
        expect(facility.full?).to be false
      end
    end
  end
end
