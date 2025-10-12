require 'rails_helper'

RSpec.describe ParkingLotFacility, type: :model do
  let(:currency) { create(:currency) }
  let(:facility) { create(:parking_lot_facility, spaces_count: 54) }
  let(:price) { create(:price, parking_lot_facility: facility, currency: currency, price_per_hour: 2.00) }

  describe '#available_spaces' do
    it 'returns total spaces count when no tickets exist' do
      expect(facility.available_spaces).to eq(54)
    end

    it 'returns spaces count minus active tickets' do
      create_list(:ticket, 3, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      expect(facility.available_spaces).to eq(51)
    end

    it 'does not count returned tickets' do
      create_list(:ticket, 5, parking_lot_facility: facility, price_at_entry: price, status: 'returned')
      expect(facility.available_spaces).to eq(54)
    end

    it 'only counts active tickets when both active and returned exist' do
      create_list(:ticket, 10, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      create_list(:ticket, 5, parking_lot_facility: facility, price_at_entry: price, status: 'returned')
      expect(facility.available_spaces).to eq(44)
    end

    it 'returns 0 when parking lot is full' do
      create_list(:ticket, 54, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      expect(facility.available_spaces).to eq(0)
    end
  end

  describe '#full?' do
    it 'returns false when spaces are available' do
      create_list(:ticket, 10, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      expect(facility.full?).to be false
    end

    it 'returns true when parking lot is exactly full' do
      create_list(:ticket, 54, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      expect(facility.full?).to be true
    end

    it 'returns false when no tickets exist' do
      expect(facility.full?).to be false
    end

    it 'returns false when one space remains' do
      create_list(:ticket, 53, parking_lot_facility: facility, price_at_entry: price, status: 'active')
      expect(facility.full?).to be false
    end
  end
end
