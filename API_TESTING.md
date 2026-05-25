# Young Explorers API Testing Guide

All command requests use the root endpoint:

```http
POST http://localhost:5000
```

Health check stays separate:

```http
GET http://localhost:5000/health
```

## Request Rule

Put the command in headers:

```http
Command: REGISTER
Content-Type: application/json
```

Put only the command data in the body:

```json
{
  "first_name": "Aline",
  "last_name": "Mutesi",
  "email": "aline@example.com",
  "phone": "+250788000000",
  "password": "password123"
}
```

For destination commands, the command itself already says the resource:

```http
Command: CREATE_DESTINATION
Content-Type: application/json
```

For update/get/delete commands that need an id, put `id` in the JSON body:

```http
Command: UPDATE_DESTINATION
Content-Type: application/json
```

```json
{
  "id": 1,
  "status": "inactive"
}
```

For protected commands, add:

```http
Authorization: Bearer YOUR_TOKEN_HERE
```

## Start Backend

```bash
cd backend
npm install
npm run dev
```

Apply database setup:

```sql
SOURCE src/config/db.sql;
SOURCE src/config/migrations/001_align_requirements.sql;
SOURCE src/config/migrations/002_indexes_and_constraints.sql;
```

If `db.sql` was already imported before, run only the migrations.

If you see an error like `Unknown column 'price_per_person' in 'field list'`, your database schema is behind the code. Run:

```bash
mysql -u root young_explorers < src/config/migrations/001_align_requirements.sql
```

Or inside MySQL:

```sql
SOURCE src/config/migrations/001_align_requirements.sql;
```

## Register Explorer

Headers:

```http
Command: REGISTER
Content-Type: application/json
```

Body:

```json
{
  "first_name": "Aline",
  "last_name": "Mutesi",
  "email": "aline@example.com",
  "phone": "+250788000000",
  "password": "password123"
}
```

cURL:

```bash
curl -X POST http://localhost:5000 \
  -H "Command: REGISTER" \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Aline","last_name":"Mutesi","email":"aline@example.com","phone":"+250788000000","password":"password123"}'
```

## Register Admin

Set `ADMIN_REGISTRATION_TOKEN` in `.env` first.

Headers:

```http
Command: REGISTER
Content-Type: application/json
```

Body:

```json
{
  "first_name": "Admin",
  "last_name": "User",
  "email": "admin@example.com",
  "phone": "+250788111111",
  "password": "password123",
  "role": "admin",
  "admin_registration_token": "YOUR_ADMIN_REGISTRATION_TOKEN"
}
```

## Login

Headers:

```http
Command: LOGIN
Content-Type: application/json
```

Body:

```json
{
  "email": "admin@example.com",
  "password": "password123"
}
```

Save the returned token.

## Current User

Headers:

```http
Command: ME
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json
```

Body:

```json
{}
```

## Create Destination

Headers:

```http
Command: CREATE_DESTINATION
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "name": "Kigali Genocide Memorial",
  "province": "Kigali",
  "district": "Gasabo",
  "category": "history",
  "short_description": "A memorial and learning center in Kigali.",
  "full_description": "A key destination for understanding Rwanda history.",
  "best_time_to_visit": "All year",
  "entry_fee": 0,
  "latitude": -1.9306,
  "longitude": 30.0606,
  "status": "active"
}
```

## List Destinations

Headers:

```http
Command: LIST_DESTINATIONS
Content-Type: application/json
```

Body:

```json
{
  "page": 1,
  "limit": 10
}
```

## Create Package

First list the available durations and copy the `id` you want:

Headers:

```http
Command: LIST_DURATIONS
Content-Type: application/json
```

Body:

```json
{
  "page": 1,
  "limit": 20
}
```

Then use one of those returned ids as `duration_id`.

Headers:

```http
Command: CREATE_PACKAGE
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "title": "5-Day Rwanda Explorer",
  "short_description": "Culture, history, and city highlights.",
  "full_description": "A youth-friendly Rwanda exploration package.",
  "duration_id": 2,
  "price_per_person": 450,
  "currency": "USD",
  "meeting_point": "Kigali International Airport",
  "emergency_contact": "+250788222222",
  "age_range": "15-25",
  "fitness_level": "easy",
  "status": "draft"
}
```

## Set Package Rules

Headers:

```http
Command: SET_PACKAGE_RULES
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "package_id": 1,
  "inclusions": ["Transport", "Meals", "Tour guide"],
  "exclusions": ["Visa fees", "Personal shopping"],
  "required_items": ["Passport", "Jacket"],
  "not_allowed_items": ["Weapons", "Drugs"]
}
```

## Update Itinerary Day

Headers:

```http
Command: UPDATE_ITINERARY_DAY
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "package_id": 1,
  "day_number": 1,
  "title": "Arrival in Kigali",
  "summary": "Airport pickup and city introduction.",
  "meals": "Dinner",
  "accommodation": "Kigali hotel",
  "start_time": "14:00:00",
  "end_time": "19:00:00"
}
```

You can also use the internal package day id in the `Id` header, but `package_id` plus `day_number` is easier for frontend and Postman testing.

## Add Destination To Itinerary Day

Headers:

```http
Command: ADD_ITINERARY_DESTINATION
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "package_day_id": 1,
  "destination_id": 1,
  "visit_order": 1,
  "activity_title": "Memorial visit",
  "activity_description": "Guided history session.",
  "arrival_time": "15:00:00",
  "departure_time": "17:00:00",
  "notes": "Respectful dress recommended."
}
```

## Create Availability

Headers:

```http
Command: CREATE_PACKAGE_AVAILABILITY
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "package_id": 1,
  "start_date": "2026-07-10",
  "end_date": "2026-07-15",
  "total_seats": 20
}
```

## Publish Package

Headers:

```http
Command: UPDATE_PACKAGE
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "id": 1,
  "status": "published"
}
```

## Get Package Details

Headers:

```http
Command: GET_PACKAGE_DETAILS
Content-Type: application/json
```

Body:

```json
{
  "id": 1
}
```

## Create Booking

Headers:

```http
Command: CREATE_BOOKING
Authorization: Bearer USER_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "package_id": 1,
  "availability_id": 1,
  "total_people": 2,
  "participants": [
    {
      "first_name": "Aline",
      "last_name": "Mutesi",
      "gender": "female",
      "nationality": "Rwandan",
      "passport_number": "P123456",
      "date_of_birth": "2002-04-12",
      "emergency_contact": "+250788000000"
    }
  ]
}
```

## Submit Payment Without File

Headers:

```http
Command: SUBMIT_PAYMENT
Authorization: Bearer USER_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "booking_id": 1,
  "amount": 900,
  "payment_method": "bank_transfer",
  "transaction_reference": "TXN-001",
  "payment_proof": "/uploads/manual-proof.jpg"
}
```

## Submit Payment With File

Headers:

```http
Command: SUBMIT_PAYMENT
Authorization: Bearer USER_TOKEN
```

Form data:

```txt
booking_id: 1
amount: 900
payment_method: bank_transfer
transaction_reference: TXN-002
file: payment-proof.jpg
```

cURL:

```bash
curl -X POST http://localhost:5000 \
  -H "Command: SUBMIT_PAYMENT" \
  -H "Authorization: Bearer USER_TOKEN" \
  -F "booking_id=1" \
  -F "amount=900" \
  -F "payment_method=bank_transfer" \
  -F "transaction_reference=TXN-002" \
  -F "file=@/absolute/path/to/payment-proof.jpg"
```

## Verify Payment

Headers:

```http
Command: VERIFY_PAYMENT
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "payment_id": 1,
  "status": "verified"
}
```

## Cancel Booking

Headers:

```http
Command: CANCEL_BOOKING
Authorization: Bearer USER_TOKEN
Content-Type: application/json
```

Body:

```json
{
  "id": 1
}
```

## Dashboard Stats

Headers:

```http
Command: GET_DASHBOARD_STATS
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

Body:

```json
{}
```

## Contact Message

Headers:

```http
Command: SEND_CONTACT_MESSAGE
Content-Type: application/json
```

Body:

```json
{
  "full_name": "Visitor Name",
  "email": "visitor@example.com",
  "subject": "Tour inquiry",
  "message": "I want to know more about Young Explorers packages."
}
```

## Upload Media

Headers:

```http
Command: UPLOAD_MEDIA
Authorization: Bearer ADMIN_TOKEN
```

Form data:

```txt
file: image.jpg
```

## Specific Listing And Destination Commands

List:

```http
Command: LIST_PACKAGES
Content-Type: application/json
```

```json
{
  "page": 1,
  "limit": 20,
  "search": ""
}
```

Get:

```http
Command: GET_DESTINATION
Content-Type: application/json
```

```json
{
  "id": 1
}
```

Update:

```http
Command: UPDATE_DESTINATION
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

```json
{
  "id": 1,
  "status": "inactive"
}
```

Delete:

```http
Command: DELETE_DESTINATION
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

```json
{
  "id": 1
}
```

## Postman Setup

Set environment variable:

```txt
base_url=http://localhost:5000
```

Use URL:

```txt
{{base_url}}
```

Put `Command` in Headers. Add `Id` or `Slug` only when the command needs a single record.

## Common Errors

- `Command is required`: missing `Command` header.
- `Authentication token is required`: missing `Authorization`.
- `Admin access is required`: explorer token used for admin command.
- `Package not found`: public user is trying to see a draft package.
- `Not enough seats are available`: booking people exceed remaining seats.
