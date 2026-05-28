# Public API Examples - Ready to Use

## Overview

These endpoints require **NO authentication** and are perfect for first-time visitors to browse your Young Explorers packages and destinations.

---

## 1️⃣ List All Published Packages

Browse all the packages available for booking.

```bash
curl -X POST http://localhost:5008 \
  -H "Command: LIST_PACKAGES" \
  -H "Content-Type: application/json" \
  -d '{
    "page": 1,
    "limit": 10,
    "search": "Rwanda"
  }'
```

**Response includes:**
- Package ID, title, slug
- Price per person & currency
- Short description
- Duration info, meeting point
- Main image URL
- Age range & fitness level

---

## 2️⃣ Get Full Package Details

View complete package itinerary, destinations, inclusions, and availability.

### By ID:
```bash
curl -X POST http://localhost:5008 \
  -H "Command: GET_PACKAGE_DETAILS" \
  -H "Content-Type: application/json" \
  -d '{"id": 1}'
```

### By Slug (better for URLs):
```bash
curl -X POST http://localhost:5008 \
  -H "Command: GET_PACKAGE_DETAILS" \
  -H "Content-Type: application/json" \
  -d '{"slug": "5-day-rwanda-explorer"}'
```

**Response includes:**
- All package fields
- Day-by-day itinerary
- Destinations visited each day (with times, activities)
- Inclusions, exclusions, required items
- Available dates & remaining seats
- Emergency contact info

---

## 3️⃣ List All Destinations

Browse all available destinations that can be visited.

```bash
curl -X POST http://localhost:5008 \
  -H "Command: LIST_DESTINATIONS" \
  -H "Content-Type: application/json" \
  -d '{
    "page": 1,
    "limit": 20,
    "search": "Volcanoes"
  }'
```

**Response includes:**
- Destination name, slug
- Location (province, district)
- Category (history, nature, culture, etc.)
- Description, best time to visit
- Entry fees
- GPS coordinates
- Main image

---

## 4️⃣ List Package Durations

See what package length options are available.

```bash
curl -X POST http://localhost:5008 \
  -H "Command: LIST_DURATIONS" \
  -H "Content-Type: application/json" \
  -d '{
    "page": 1,
    "limit": 20
  }'
```

**Response includes:**
- Duration ID (needed to create packages)
- Title (e.g., "5 Days")
- Total days
- Status

---

## Frontend Integration Examples

### React Example

```javascript
async function getPublicPackages(page = 1, search = '') {
  const response = await fetch('http://localhost:5008', {
    method: 'POST',
    headers: {
      'Command': 'LIST_PACKAGES',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      page,
      limit: 10,
      search
    })
  });
  
  const result = await response.json();
  return result.data.rows;
}

async function getPackageDetails(slug) {
  const response = await fetch('http://localhost:5008', {
    method: 'POST',
    headers: {
      'Command': 'GET_PACKAGE_DETAILS',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ slug })
  });
  
  const result = await response.json();
  return result.data;
}
```

### Vue Example

```vue
<script setup>
import { ref, onMounted } from 'vue'

const packages = ref([])
const loading = ref(false)

async function fetchPackages() {
  loading.value = true
  try {
    const response = await fetch('http://localhost:5008', {
      method: 'POST',
      headers: {
        'Command': 'LIST_PACKAGES',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ page: 1, limit: 10 })
    })
    const result = await response.json()
    packages.value = result.data.rows
  } finally {
    loading.value = false
  }
}

onMounted(fetchPackages)
</script>

<template>
  <div v-if="loading">Loading packages...</div>
  <div v-else>
    <div v-for="pkg in packages" :key="pkg.id" class="package-card">
      <h3>{{ pkg.title }}</h3>
      <p>{{ pkg.short_description }}</p>
      <p>Price: ${{ pkg.price_per_person }} {{ pkg.currency }}</p>
    </div>
  </div>
</template>
```

---

## Key Points to Remember

✅ **These endpoints are public** - No authentication token needed  
✅ **First-time visitors** can use them immediately  
✅ **Only shows published content**:
  - Packages with `status: "published"`
  - Durations with `status: "active"`
  - All destinations
  
✅ **Filtering works**:
  - `search`: Search by title, description, location
  - `page` & `limit`: For pagination
  
❌ **Cannot create/modify** without authentication (that's intentional!)

---

## Testing Workflow

1. **Start the backend**: `npm run dev` (runs on port 5008)
2. **Call LIST_PACKAGES** to see what's available
3. **Call GET_PACKAGE_DETAILS** for full info
4. **Integrate into your frontend** using the examples above
5. **When visitor is ready to book**, they authenticate and use booking endpoints

---

## Troubleshooting

| Error | Solution |
|-------|----------|
| `Package not found` | Package has `status: "draft"`. It needs to be `status: "published"` to show |
| `Unknown command` | Check spelling of command name exactly |
| `Connection refused` | Make sure backend is running on port 5008 |
| No results | Make sure packages/destinations are created and published |

---

## Advanced: Combining Data

Get a package and its full destination info:

```bash
# 1. Get package details
curl -X POST http://localhost:5008 \
  -H "Command: GET_PACKAGE_DETAILS" \
  -H "Content-Type: application/json" \
  -d '{"slug": "5-day-rwanda-explorer"}'

# Response includes all destinations visited in package.days[].destinations[]
# Use destination data directly - no separate calls needed!
```

The package details response includes **all** destinations visited during the package, including:
- Destination name & location
- Visit order
- Activity title & description
- Arrival/departure times
- Notes

This makes it perfect for displaying a complete itinerary to visitors!
