class ChangeNameToNotNullInParkingLotFacilities < ActiveRecord::Migration[8.0]
  def change
    change_column_null :parking_lot_facilities, :name, false
  end
end
