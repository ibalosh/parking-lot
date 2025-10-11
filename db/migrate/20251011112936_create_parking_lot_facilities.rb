class CreateParkingLotFacilities < ActiveRecord::Migration[8.0]
  def change
    create_table :parking_lot_facilities do |t|
      t.string :name
      t.integer :spaces_count, null: false
      t.timestamps

      t.check_constraint 'spaces_count >= 0', name: 'spaces_count_positive'
    end
  end
end
