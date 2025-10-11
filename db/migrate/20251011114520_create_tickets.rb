class CreateTickets < ActiveRecord::Migration[8.0]
  def change
    create_table :tickets do |t|
      t.string :barcode, null: false
      t.references :parking_lot_facility, null: false, foreign_key: true
      t.datetime :issued_at, null: false

      t.timestamps
    end
    add_index :tickets, :barcode, unique: true
  end
end
