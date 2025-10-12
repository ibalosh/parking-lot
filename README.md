# 🅿️ Parking Lot Management System

[![CI](https://github.com/ibalosh/parking-lot/actions/workflows/ci.yml/badge.svg)](https://github.com/ibalosh/parking-lot/actions/workflows/ci.yml)

A RESTful API for managing a parking lot with X amount of spaces.

## Requirements

- Ruby version in `.ruby-version` file
- Rails 8+
- Bundler
- SQLite3

## Setup

```bash
bundle install
bin/rails db:setup
```

Once the setup is complete, you can start the Rails server:

```
rails server
```

## Running Tests

```bash
bundle exec rspec
```

## Documentation

- **[API Endpoints](docs/API_ENDPOINTS.md)** - Detailed endpoint documentation with request/response examples
- **[Database Schema](docs/DATABASE.md)** - Entity relationship diagram and table descriptions
- **[Postman Collection](docs/Parking-Lot.postman_collection.json)** - Import this collection to test the API in Postman

## Architecture

### Models

- **ParkingLotFacility** - Manages parking lot capacity (54 spaces)
- **Ticket** - Parking tickets with barcode, status (active/returned), and timestamps
- **Payment** - Payment records linked to tickets
- **Price** - Configurable pricing (€2/hour)
- **Currency** - Multi-currency support

### Service Layer

- **PaymentService** - Handles payment creation with pessimistic locking to prevent race conditions where concurrent
  requests could create duplicate payments

### Key Features

- **Race condition protection**: Pessimistic locking prevents duplicate payments and overbooking
- **Data integrity**: Comprehensive validations and unique constraints
- **Idempotent operations**: Multiple payment attempts return existing payment
- **15-minute grace period**: Payment valid for 15 minutes after purchase
- **Dynamic pricing**: Calculated per started hour based on entry time

## Design Decisions

1. **Pessimistic Locking** - Used in `PaymentService` and `create_ticket_with_lock` to prevent race conditions in
   high-concurrency scenarios (duplicate payments, overbooking).

2. **Service Layer** - `PaymentService` extracts complex payment logic from the controller, making it easier to test and
   maintain.

3. **Active Tickets Scope** - Only active tickets count toward capacity; returned tickets free up spaces immediately.

4. **Barcode as Identifier** - Tickets identified by barcode instead of database ID for better UX at physical machines.

5. **Separate ID and Barcode Fields** - The tickets table uses both an auto-incrementing `id` (primary key) and a
   `barcode` field (unique indexed string). While the barcode could technically serve as the primary key, keeping a
   separate integer ID provides several benefits:
   - **Performance**: Integer primary keys are more efficient for joins and foreign key relationships (e.g., payments
     linking to tickets)
   - **Flexibility**: If barcode format needs to change (e.g., from numeric to alphanumeric), it won't affect foreign
     key relationships
   - **Convention**: Follows Rails and ActiveRecord conventions, making the codebase more maintainable

   The barcode serves as a natural key for API consumers and physical interactions, while the ID serves as a technical
   key for internal database relationships.

6. **Payment Expiration** - 15-minute window ensures customers don't pay and then park for hours before leaving.

## Design Notes & Assumptions

### Database & Multi-tenancy

- **Single Parking Lot**: Currently, the API uses the first parking lot facility from the database. This can be easily
  extended to support multiple parking lots by accepting a facility ID parameter in requests.
- **Database Choice**: SQLite for simplicity and ease of setup. Production deployments should use PostgreSQL or MySQL.

### Pricing & Currency

- **Multi-currency Support**: The system supports multiple currencies (Currency model), but each parking lot uses a
  single currency defined in its Price configuration.
- **Price History**: Tickets capture the price configuration at the time of entry (`price_at_entry`), ensuring
  historical accuracy even if pricing changes later.
- **Hourly Pricing**: Every started hour is billed as a full hour. For example, parking for 1 hour and 1 second costs
  the same as 2 full hours. This can be made more granular (e.g., 15-minute increments) if needed.

### Payment System

- **Payment Methods**: Stored as denormalized string values (`credit_card`, `debit_card`, `cash`) with validation. No
  separate payment method table was created for simplicity. This can be normalized if payment method metadata is needed
  in the future.
- **Multiple Payments**: The system allows multiple payment records per ticket (e.g., if payment expires after 15
  minutes and customer pays again). The latest payment is used to determine ticket state.
- **Idempotent Payments**: Attempting to pay an already-paid ticket returns the existing payment instead of creating a
  duplicate (HTTP 200 instead of 201).

### Ticket Lifecycle

- **Ticket States**: Tickets have two states: `active` (default) and `returned`. Only active tickets count toward
  parking capacity.
- **Ticket Return**: The bonus endpoint (PUT `/api/tickets/{barcode}`) allows marking tickets as returned when cars
  exit. This immediately frees up a parking space.
- **No Authentication**: As per requirements, no authentication or authorization is implemented. In production, this
  would be required.

### API Design

- **Versioning**: All endpoints are namespaced under `/api` to allow for future versioning (`/api/v2`, etc.).
- **Error Handling**: Consistent error responses with appropriate HTTP status codes (404 for not found, 422 for
  validation errors, 503 for parking lot full).