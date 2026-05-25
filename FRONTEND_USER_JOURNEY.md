# Young Explorers Frontend User Journey

The frontend uses one command endpoint:

```http
POST /
```

Commands are sent in request headers, not in the JSON body.

Example:

```http
Command: LIST_PACKAGES
Content-Type: application/json
```

Body:

```json
{
  "page": 1,
  "limit": 12
}
```

Protected requests also include:

```http
Authorization: Bearer <token>
```

## Roles

Public visitors can browse published packages, active destinations, register, login, and send contact messages.

Explorers can browse, book packages, submit payment proof, view their bookings, update profile, and cancel their own bookings.

Admins can manage destinations, packages, itinerary, availability, bookings, payments, users, media, and messages.

## API Client Shape

Recommended JSON helper:

```js
export async function sendCommand({ command, body = {}, token }) {
  const response = await fetch(import.meta.env.VITE_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Command: command,
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });

  const json = await response.json();

  if (!response.ok || !json.ok) {
    throw new Error(json.message || "Request failed");
  }

  return json.data;
}
```

Recommended multipart helper:

```js
export async function sendMultipartCommand({ command, body = {}, file, token }) {
  const formData = new FormData();

  for (const [key, value] of Object.entries(body)) {
    formData.append(key, value);
  }

  if (file) {
    formData.append("file", file);
  }

  const response = await fetch(import.meta.env.VITE_API_URL, {
    method: "POST",
    headers: {
      Command: command,
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: formData,
  });

  const json = await response.json();

  if (!response.ok || !json.ok) {
    throw new Error(json.message || "Request failed");
  }

  return json.data;
}
```

## Public Journey

Home page:

- Fetch featured packages with `Command: LIST_PACKAGES`.
- Fetch destinations with `Command: LIST_DESTINATIONS`.
- Show calls to action for packages, destinations, register, and login.

Packages page:

```js
sendCommand({
  command: "LIST_PACKAGES",
  body: { page: 1, limit: 12 }
});
```

Package details page:

```js
sendCommand({
  command: "GET_PACKAGE_DETAILS",
  body: { id: 1 }
});
```

Contact page:

```js
sendCommand({
  command: "SEND_CONTACT_MESSAGE",
  body: {
    full_name: "Visitor Name",
    email: "visitor@example.com",
    subject: "Tour inquiry",
    message: "I want to know more."
  }
});
```

## Authentication Journey

Register:

```js
sendCommand({
  command: "REGISTER",
  body: {
    first_name: "Aline",
    last_name: "Mutesi",
    email: "aline@example.com",
    phone: "+250788000000",
    password: "password123"
  }
});
```

Login:

```js
sendCommand({
  command: "LOGIN",
  body: {
    email: "aline@example.com",
    password: "password123"
  }
});
```

Restore session:

```js
sendCommand({
  command: "ME",
  token,
  body: {}
});
```

## Explorer Booking Journey

1. Explorer opens package details with `GET_PACKAGE_DETAILS`.
2. Explorer selects an availability date with remaining seats.
3. Explorer selects number of people.
4. Explorer adds participant details.
5. Frontend sends `CREATE_BOOKING`.

```js
sendCommand({
  command: "CREATE_BOOKING",
  token,
  body: {
    package_id: 1,
    availability_id: 1,
    total_people: 2,
    participants: []
  }
});
```

Payment proof upload:

```js
sendMultipartCommand({
  command: "SUBMIT_PAYMENT",
  token,
  body: {
    booking_id: 1,
    amount: 900,
    payment_method: "bank_transfer",
    transaction_reference: "TXN-001"
  },
  file
});
```

Explorer bookings:

```js
sendCommand({
  command: "LIST_BOOKINGS",
  token,
  body: { page: 1, limit: 20 }
});
```

Cancel booking:

```js
sendCommand({
  command: "CANCEL_BOOKING",
  token,
  body: { id: 1 }
});
```

## Admin Journey

Dashboard:

```js
sendCommand({
  command: "GET_DASHBOARD_STATS",
  token,
  body: {}
});
```

Create destination:

```js
sendCommand({
  command: "CREATE_DESTINATION",
  token,
  body: {
    name: "Kigali Genocide Memorial",
    province: "Kigali",
    district: "Gasabo",
    category: "history",
    status: "active"
  }
});
```

Create package:

```js
sendCommand({
  command: "CREATE_PACKAGE",
  token,
  body: {
    title: "5-Day Rwanda Explorer",
    duration_id: 2,
    price_per_person: 450,
    currency: "USD",
    status: "draft"
  }
});
```

Publish package:

```js
sendCommand({
  command: "UPDATE_PACKAGE",
  token,
  body: { id: 1, status: "published" }
});
```

Create availability:

```js
sendCommand({
  command: "CREATE_PACKAGE_AVAILABILITY",
  token,
  body: {
    package_id: 1,
    start_date: "2026-07-10",
    end_date: "2026-07-15",
    total_seats: 20
  }
});
```

Verify payment:

```js
sendCommand({
  command: "VERIFY_PAYMENT",
  token,
  body: {
    payment_id: 1,
    status: "verified"
  }
});
```

## UI States

Every page should handle loading, empty, error, unauthorized, forbidden, and success states.

Booking screens should handle no seats, pending payment, waiting for verification, confirmed, cancelled, and expired.
