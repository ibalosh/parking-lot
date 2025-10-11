class AddPriceToTickets < ActiveRecord::Migration[8.0]
  def change
    add_reference :tickets, :price, null: false, foreign_key: true
  end
end
