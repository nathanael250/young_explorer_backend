# Young Explorers API

Node.js backend using one command endpoint instead of many route paths.

## Setup

```bash
npm install
cp .env.example .env
npm run dev
```

Import `src/config/db.sql` into MySQL before starting the server.

If the database already exists from an earlier version, run:

```sql
SOURCE src/config/migrations/001_align_requirements.sql;
SOURCE src/config/migrations/002_indexes_and_constraints.sql;
```

## Command Endpoint

All main API actions go through:

```http
POST /
```

For full copy-paste testing examples, see `API_TESTING.md`.

For frontend screens, roles, and user journeys, see `FRONTEND_USER_JOURNEY.md`.

Command request shape:

```http
Command: LIST_PACKAGES
Content-Type: application/json
```

Body:

```json
{
  "search": "",
  "page": 1,
  "limit": 20
}
```

Useful commands:

- `HEALTH`
- `REGISTER`
- `LOGIN`
- `ME`
- `UPDATE_PROFILE`
- `CHANGE_PASSWORD`
- `SET_USER_STATUS`
- `LIST_PACKAGES`
- `LIST_DESTINATIONS`
- `GET_DESTINATION`
- `CREATE_DESTINATION`
- `UPDATE_DESTINATION`
- `DELETE_DESTINATION`
- `LIST_DURATIONS`
- `LIST_BOOKINGS`
- `LIST_PAYMENTS`
- `LIST_USERS`
- `LIST_MESSAGES`
- `LIST_MEDIA`
- `CREATE_PACKAGE`
- `UPDATE_PACKAGE`
- `GET_PACKAGE_DETAILS`
- `SET_PACKAGE_RULES`
- `CREATE_PACKAGE_AVAILABILITY`
- `UPDATE_PACKAGE_AVAILABILITY`
- `UPDATE_ITINERARY_DAY`
- `ADD_ITINERARY_DESTINATION`
- `REMOVE_ITINERARY_DESTINATION`
- `CREATE_BOOKING`
- `CANCEL_BOOKING`
- `EXPIRE_PENDING_BOOKINGS`
- `SUBMIT_PAYMENT`
- `VERIFY_PAYMENT`
- `GET_DASHBOARD_STATS`
- `SEND_CONTACT_MESSAGE`
- `UPLOAD_MEDIA`

Resource logic lives in `src/models/masterModel.js`; controllers and routes stay thin.

## Production

Run with PM2:

```bash
npm install --omit=dev
pm2 start ecosystem.config.js
pm2 save
```

Recommended Nginx proxy target:

```nginx
location / {
  proxy_pass http://127.0.0.1:5000;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
}
```

## Domain Workflows

Create a package and automatically generate itinerary days:

```http
Command: CREATE_PACKAGE
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

Use `LIST_DURATIONS` first, then pass one active duration `id` as `duration_id`.

```json
{
  "title": "5-Day Rwanda Explorer",
  "short_description": "Culture, wildlife, and Kigali highlights",
  "duration_id": 2,
  "price_per_person": 450,
  "currency": "USD",
  "status": "draft"
}
```

Get a package with days, destinations, rules, and availability:

```http
Command: GET_PACKAGE_DETAILS
Slug: 5-day-rwanda-explorer
Content-Type: application/json
```

Create a seat-aware booking:

```http
Command: CREATE_BOOKING
Authorization: Bearer USER_TOKEN
Content-Type: application/json
```

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

Submit payment proof using multipart form data with `Command: SUBMIT_PAYMENT` in headers and payment fields plus `file` in the form body.

Admin verifies a payment:

```http
Command: VERIFY_PAYMENT
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

```json
{
  "payment_id": 1,
  "status": "verified"
}
```

Create availability:

```http
Command: CREATE_PACKAGE_AVAILABILITY
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

```json
{
  "package_id": 1,
  "start_date": "2026-07-10",
  "end_date": "2026-07-15",
  "total_seats": 20
}
```

Update an itinerary day:

```http
Command: UPDATE_ITINERARY_DAY
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

```json
{
  "package_id": 1,
  "day_number": 1,
  "title": "Arrival in Kigali",
  "summary": "Airport pickup and city introduction",
  "meals": "Dinner",
  "accommodation": "Kigali hotel"
}
```

Set package rules:

```http
Command: SET_PACKAGE_RULES
Authorization: Bearer ADMIN_TOKEN
Content-Type: application/json
```

```json
{
  "package_id": 1,
  "inclusions": ["Transport", "Meals", "Guide"],
  "exclusions": ["Visa fees"],
  "required_items": ["Passport", "Jacket"],
  "not_allowed_items": ["Weapons", "Drugs"]
}
```

Send a public contact message:

```http
Command: SEND_CONTACT_MESSAGE
Content-Type: application/json
```

```json
{
  "full_name": "Visitor Name",
  "email": "visitor@example.com",
  "subject": "Tour inquiry",
  "message": "I would like to know more about your packages."
}
```
