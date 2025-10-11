class CreatePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :prices do |t|
      t.references :parking_lot_facility, null: false, foreign_key: true
      t.decimal :price_per_hour, precision: 10, scale: 2, null: false
      t.references :currency, null: false, foreign_key: true

      t.timestamps
    end
  end
end
