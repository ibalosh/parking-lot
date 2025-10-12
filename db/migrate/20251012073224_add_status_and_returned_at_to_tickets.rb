class AddStatusAndReturnedAtToTickets < ActiveRecord::Migration[8.0]
  def change
    add_column :tickets, :status, :string, null: false, default: "active"
    add_column :tickets, :returned_at, :datetime
  end
end
