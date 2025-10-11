# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create Euro currency
euro = Currency.find_or_create_by!(code: "EUR") do |currency|
  currency.name = "Euro"
  currency.symbol = "€"
end

puts "✓ Created Euro currency"

# Create default parking lot facility with 54 spaces
facility = ParkingLotFacility.find_or_create_by!(name: "Main Parking Lot") do |f|
  f.spaces_count = 54
end

puts "✓ Created default parking lot facility with 54 spaces"

# Create default price: €2 per hour
Price.find_or_create_by!(parking_lot_facility: facility) do |price|
  price.price_per_hour = 2.00
  price.currency = euro
end

puts "✓ Created default price: €2 per hour"
