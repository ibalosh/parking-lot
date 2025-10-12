# API Endpoints

## 1. Create Ticket (Task #1)

**POST** `/api/tickets`

Creates a new parking ticket with a unique 16-character hex barcode. Returns error if parking lot is full.

**Response:**

```json
{
  "barcode": "a1b2c3d4e5f67890",
  "issued_at": "2025-01-12T10:00:00Z"
}
```

## 2. Get Ticket Price (Task #2)

**GET** `/api/tickets/{barcode}`

Calculates the parking fee based on time parked. Every started hour costs €2. Returns 0 if already paid.

**Response:**

```json
{
  "barcode": "a1b2c3d4e5f67890",
  "issued_at": "2025-01-12T10:00:00Z",
  "price": "4 €"
}
```

## 3. Create Payment (Task #3)

**POST** `/api/tickets/{barcode}/payments`

Records a payment for a ticket. Payment methods: `credit_card`, `debit_card`, `cash`.

**Request:**

```json
{
  "payment": {
    "payment_method": "credit_card"
  }
}
```

**Response:**

```json
{
  "barcode": "a1b2c3d4e5f67890",
  "amount": "4 €",
  "payment_method": "credit_card",
  "paid_at": "2025-01-12T12:00:00Z"
}
```

## 4. Check Ticket State (Task #4)

**GET** `/api/tickets/{barcode}/state`

Returns whether a ticket is paid or unpaid. Payment is valid for 15 minutes.

**Response:**

```json
{
  "barcode": "a1b2c3d4e5f67890",
  "state": "paid"
}
```

## 5. Get Free Spaces (Task #5)

**GET** `/api/free-spaces`

Returns the number of available parking spaces.

**Response:**

```json
{
  "available_spaces": 42,
  "total_spaces": 54
}
```

## 6. Return Ticket

**PUT** `/api/tickets/{barcode}`

Marks a ticket as returned when the car exits. Only allowed if paid and within 15 minutes of payment.

**Request:**

```json
{
  "status": "returned"
}
```

**Response:**

```json
{
  "barcode": "a1b2c3d4e5f67890",
  "status": "returned",
  "returned_at": "2025-01-12T12:10:00Z"
}
```
