# Smart Local Planner — REST API Specification

> **Base URL:** `http://localhost:8080/api/v1` (Local) / `https://api.smartlocalplanner.onrender.com/api/v1` (Production)  
> **Protocol:** HTTPS / JSON (`Content-Type: application/json; charset=UTF-8`)  
> **Authentication:** Bearer Token via HTTP Header `Authorization: Bearer <access_token>`  

---

## 1. Authentication Domain (`/api/v1/auth`)

### 1.1. Register Account
* **Endpoint:** `POST /api/v1/auth/register`
* **Access:** Public (Rate limited: 5 requests/min per IP)

#### Request Body
```json
{
  "email": "traveler@example.com",
  "password": "SecurePassword123!",
  "fullName": "Nguyen Van A"
}
```

#### Response: `201 Created`
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "d8f3b21a-4c2e-4b68-912a-590f23b8...",
  "tokenType": "Bearer",
  "expiresIn": 1800,
  "user": {
    "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    "email": "traveler@example.com",
    "fullName": "Nguyen Van A",
    "role": "ROLE_USER"
  }
}
```

---

### 1.2. Login with Credentials
* **Endpoint:** `POST /api/v1/auth/login`
* **Access:** Public (Rate limited: 5 requests/min per IP)

#### Request Body
```json
{
  "email": "traveler@example.com",
  "password": "SecurePassword123!"
}
```

#### Response: `200 OK`
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "d8f3b21a-4c2e-4b68-912a-590f23b8...",
  "tokenType": "Bearer",
  "expiresIn": 1800,
  "user": {
    "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    "email": "traveler@example.com",
    "fullName": "Nguyen Van A",
    "role": "ROLE_USER"
  }
}
```

---

### 1.3. Refresh Access Token (Token Rotation)
* **Endpoint:** `POST /api/v1/auth/refresh-token`
* **Access:** Public

#### Request Body
```json
{
  "refreshToken": "d8f3b21a-4c2e-4b68-912a-590f23b8..."
}
```

#### Response: `200 OK`
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.new...",
  "refreshToken": "e912a43b-7f1c-4b68-821a-681b94c2.new...",
  "tokenType": "Bearer",
  "expiresIn": 1800,
  "user": {
    "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
    "email": "traveler@example.com",
    "fullName": "Nguyen Van A",
    "role": "ROLE_USER"
  }
}
```

---

### 1.4. Logout Session
* **Endpoint:** `POST /api/v1/auth/logout`
* **Access:** Public / Optional Bearer (`Authorization: Bearer <access_token>`)

#### Request Body (Optional)
```json
{
  "refreshToken": "d8f3b21a-4c2e-4b68-912a-590f23b8..."
}
```

#### Response: `200 OK`
```json
{
  "message": "User logged out successfully."
}
```

---

## 2. Places Discovery Domain (`/api/v1/places`)

### 2.1. Search and Paginate Places
* **Endpoint:** `GET /api/v1/places`
* **Access:** Public
* **Query Parameters:**
  - `query` (string, optional): Keyword search matching place name or address
  - `category` (string, optional): `ATTRACTION`, `CULTURE`, `NATURE`, `BEACH`, `RESTAURANT`, `CAFE`
  - `priceLevel` (int, optional): `1`, `2`, `3`, `4`
  - `page` (int, default: `0`): Page index
  - `size` (int, default: `10`): Items per page
  - `sort` (string, default: `averageRating,desc`): Sort expression

#### Response: `200 OK`
```json
{
  "content": [
    {
      "id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
      "name": "The Coffee House - Landmark 81",
      "category": "CAFE",
      "address": "Floor B1, Landmark 81, Binh Thanh District, HCMC",
      "latitude": 10.7951,
      "longitude": 106.7218,
      "priceLevel": 2,
      "openingHours": "07:00 - 22:30",
      "imageUrl": "https://res.cloudinary.com/smartplanner/image/upload/v1/landmark.webp",
      "averageRating": 4.6,
      "totalReviews": 38
    }
  ],
  "pageNumber": 0,
  "pageSize": 10,
  "totalElements": 48,
  "totalPages": 5,
  "isLast": false
}
```

---

### 2.2. Get Place Details
* **Endpoint:** `GET /api/v1/places/{id}`
* **Access:** Public

#### Response: `200 OK`
```json
{
  "id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
  "name": "The Coffee House - Landmark 81",
  "description": "Modern coffee shop located in Vietnam's tallest tower with stunning skyline views.",
  "category": "CAFE",
  "address": "Floor B1, Landmark 81, Binh Thanh District, HCMC",
  "latitude": 10.7951,
  "longitude": 106.7218,
  "priceLevel": 2,
  "openingHours": "07:00 - 22:30",
  "imageUrl": "https://res.cloudinary.com/smartplanner/image/upload/v1/landmark.webp",
  "averageRating": 4.6,
  "totalReviews": 38,
  "createdAt": "2026-10-18T08:00:00Z",
  "updatedAt": "2026-10-18T08:00:00Z"
}
```

---

### 2.3. Get Top-Rated Places in Category
* **Endpoint:** `GET /api/v1/places/top`
* **Access:** Public
* **Query Parameters:**
  - `category` (string, required): Category identifier (case-insensitive, e.g. `CAFE`, `culture`, `attraction`)

#### Response: `200 OK`
```json
[
  {
    "id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
    "name": "Cầu Rồng",
    "description": "Cây cầu biểu tượng bắc qua sông Hàn với kiến trúc mô phỏng rồng thời Lý.",
    "category": "ATTRACTION",
    "address": "Đường Nguyễn Văn Linh, Hải Châu, Đà Nẵng",
    "latitude": 16.0611,
    "longitude": 108.2272,
    "priceLevel": 1,
    "openingHours": "24/7 (Phun lửa 21:00 T7 & CN)",
    "imageUrl": "https://images.unsplash.com/photo-1559592413-7cec4d0cae2b",
    "averageRating": 4.8,
    "totalReviews": 1250,
    "createdAt": "2026-10-18T08:00:00Z",
    "updatedAt": "2026-10-18T08:00:00Z"
  }
]
```

---

## 3. Favorites Domain (`/api/v1/favorites`)

### 3.1. List User Favorites
* **Endpoint:** `GET /api/v1/favorites`
* **Access:** Required (`Authorization: Bearer <access_token>`)

#### Response: `200 OK`
```json
[
  {
    "id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
    "name": "The Coffee House - Landmark 81",
    "description": "Modern coffee shop located in Vietnam's tallest tower with stunning skyline views.",
    "category": "CAFE",
    "address": "Floor B1, Landmark 81, Binh Thanh District, HCMC",
    "latitude": 10.7951,
    "longitude": 106.7218,
    "priceLevel": 2,
    "openingHours": "07:00 - 22:30",
    "imageUrl": "https://res.cloudinary.com/smartplanner/image/upload/v1/landmark.webp",
    "averageRating": 4.6,
    "totalReviews": 38,
    "createdAt": "2026-10-18T08:00:00Z",
    "updatedAt": "2026-10-18T08:00:00Z"
  }
]
```

---

### 3.2. Add to Favorites
* **Endpoint:** `POST /api/v1/favorites/{placeId}`
* **Access:** Required

#### Response: `201 Created`
```json
{
  "message": "Place added to favorites."
}
```

---

### 3.3. Remove from Favorites
* **Endpoint:** `DELETE /api/v1/favorites/{placeId}`
* **Access:** Required

#### Response: `200 OK`
```json
{
  "message": "Place removed from favorites."
}
```

---

## 4. Itineraries Domain (`/api/v1/itineraries`)

### 4.1. List Personal Itineraries
* **Endpoint:** `GET /api/v1/itineraries`
* **Access:** Required (Bearer JWT)
* **Query Parameters:**
  * `page` (optional, default `0`): Zero-based page index.
  * `size` (optional, default `10`): Number of itineraries per page.
  * `sort` (optional, default `createdAt,desc`): Sort field and direction.

#### Response: `200 OK`
```json
{
  "data": [
    {
      "id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
      "title": "Weekend in Saigon Highlights",
      "description": "2-day discovery of iconic landmarks and coffee culture.",
      "startDate": "2026-10-24",
      "endDate": "2026-10-25",
      "totalDays": 2,
      "totalPlaces": 4,
      "isPublic": false,
      "createdAt": "2026-10-18T08:00:00Z",
      "updatedAt": "2026-10-18T08:00:00Z"
    }
  ],
  "pageNumber": 0,
  "pageSize": 10,
  "totalElements": 1,
  "totalPages": 1,
  "isLast": true
}
```

---

### 4.2. Create Itinerary
* **Endpoint:** `POST /api/v1/itineraries`
* **Access:** Required (Bearer JWT)

#### Request Body
```json
{
  "title": "Weekend in Saigon Highlights",
  "description": "2-day discovery of iconic landmarks and coffee culture.",
  "startDate": "2026-10-24",
  "endDate": "2026-10-25",
  "isPublic": false,
  "items": [
    {
      "placeId": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
      "dayNumber": 1,
      "orderIndex": 0,
      "startTime": "09:00:00",
      "notes": "Morning coffee meeting"
    }
  ]
}
```

#### Field Constraints:
* `title`: String, required, 1–255 characters (`@NotBlank`, `@Size(max = 255)`).
* `description`: String, optional, max 1000 characters.
* `startDate`: String (ISO-8601 `YYYY-MM-DD`), optional.
* `endDate`: String (ISO-8601 `YYYY-MM-DD`), optional. Must be on or after `startDate` if both provided.
* `isPublic`: Boolean, default `false` (retained in schema; private in Sprint 3).
* `items`: Array of schedule items, optional (can create empty itinerary and populate later).
  * `placeId`: UUID, required, must exist in `places` table.
  * `dayNumber`: Integer, required, minimum `1` (`@Min(1)`).
  * `orderIndex`: Integer, required, minimum `0` (`@Min(0)`).
  * `startTime`: String (ISO-8601 `HH:mm:ss`), optional.
  * `notes`: String, optional, max 500 characters.

#### Response: `201 Created`
```json
{
  "id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
  "title": "Weekend in Saigon Highlights",
  "description": "2-day discovery of iconic landmarks and coffee culture.",
  "startDate": "2026-10-24",
  "endDate": "2026-10-25",
  "totalDays": 2,
  "totalPlaces": 1,
  "isPublic": false,
  "createdAt": "2026-10-18T08:00:00Z",
  "updatedAt": "2026-10-18T08:00:00Z"
}
```

---

### 4.3. Get Itinerary Detail with Schedule
* **Endpoint:** `GET /api/v1/itineraries/{id}`
* **Access:** Required (Owner only). Attempting to access an itinerary owned by another user returns `403 FORBIDDEN_ACCESS`. Non-existent itineraries return `404 RESOURCE_NOT_FOUND`.

#### Response: `200 OK`
```json
{
  "id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
  "title": "Weekend in Saigon Highlights",
  "description": "2-day discovery of iconic landmarks and coffee culture.",
  "startDate": "2026-10-24",
  "endDate": "2026-10-25",
  "isPublic": false,
  "totalDays": 2,
  "totalPlaces": 1,
  "items": [
    {
      "id": "d3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44",
      "dayNumber": 1,
      "orderIndex": 0,
      "startTime": "09:00:00",
      "notes": "Morning coffee meeting",
      "place": {
        "id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
        "name": "The Coffee House - Landmark 81",
        "address": "Floor B1, Landmark 81, Binh Thanh District, HCMC",
        "category": "CAFE",
        "priceLevel": 2,
        "imageUrl": "https://res.cloudinary.com/.../landmark.webp",
        "latitude": 10.7951,
        "longitude": 106.7218
      }
    }
  ],
  "createdAt": "2026-10-18T08:00:00Z",
  "updatedAt": "2026-10-18T08:00:00Z"
}
```

---

### 4.4. Update Itinerary (Atomic Full-Schedule Replacement)
* **Endpoint:** `PUT /api/v1/itineraries/{id}`
* **Access:** Required + Owner only (`403 FORBIDDEN_ACCESS` on cross-tenant mutation).
* **Schedule Mutation Policy:**
  * When this endpoint is invoked, the top-level itinerary metadata (`title`, `description`, `startDate`, `endDate`, `isPublic`) is updated.
  * The entire schedule collection (`itinerary_items`) is replaced atomically in a single database transaction (`@Transactional`). Any previously existing items omitted from the payload are deleted (`orphanRemoval = true`), eliminating orphaned records or out-of-order sequence drift.

#### Request Body
```json
{
  "title": "Updated Saigon 3-Day Trip",
  "description": "Extended trip including culinary exploration.",
  "startDate": "2026-10-24",
  "endDate": "2026-10-26",
  "isPublic": false,
  "items": [
    {
      "placeId": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
      "dayNumber": 1,
      "orderIndex": 0,
      "startTime": "09:30:00",
      "notes": "Updated morning coffee schedule"
    }
  ]
}
```

#### Response: `200 OK`
```json
{
  "id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
  "title": "Updated Saigon 3-Day Trip",
  "description": "Extended trip including culinary exploration.",
  "startDate": "2026-10-24",
  "endDate": "2026-10-26",
  "isPublic": false,
  "totalDays": 3,
  "totalPlaces": 1,
  "items": [
    {
      "id": "e5eebc99-9c0b-4ef8-bb6d-6bb9bd380a66",
      "dayNumber": 1,
      "orderIndex": 0,
      "startTime": "09:30:00",
      "notes": "Updated morning coffee schedule",
      "place": {
        "id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
        "name": "The Coffee House - Landmark 81",
        "address": "Floor B1, Landmark 81, Binh Thanh District, HCMC",
        "category": "CAFE",
        "priceLevel": 2,
        "imageUrl": "https://res.cloudinary.com/.../landmark.webp",
        "latitude": 10.7951,
        "longitude": 106.7218
      }
    }
  ],
  "createdAt": "2026-10-18T08:00:00Z",
  "updatedAt": "2026-10-18T10:30:00Z"
}
```

---

### 4.5. Delete Itinerary
* **Endpoint:** `DELETE /api/v1/itineraries/{id}`
* **Access:** Required + Owner only (`403 FORBIDDEN_ACCESS` on cross-tenant deletion).
* **Cascade Semantics:** Deleting an itinerary automatically cascades to delete all linked `itinerary_items` (`ON DELETE CASCADE`).

#### Response: `204 No Content`

---

## 5. Reviews Domain (`/api/v1/places/{id}/reviews`)

### 5.1. List Reviews for Place
* **Endpoint:** `GET /api/v1/places/{id}/reviews`
* **Access:** Public
* **Query Parameters:**
  * `page` (optional, default `0`): Zero-based page index.
  * `size` (optional, default `10`): Number of reviews per page.
  * `sort` (optional, default `createdAt,desc`): Sort field and direction.

#### Response: `200 OK`
```json
{
  "data": [
    {
      "id": "e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55",
      "userId": "a1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
      "authorName": "Tran Thi B",
      "authorAvatar": "https://res.cloudinary.com/.../avatar.webp",
      "rating": 5,
      "comment": "Wonderful atmosphere and delicious signature coffee!",
      "createdAt": "2026-10-15T14:20:00Z"
    }
  ],
  "pageNumber": 0,
  "pageSize": 10,
  "totalElements": 1,
  "totalPages": 1,
  "isLast": true
}
```

---

### 5.2. Submit Review
* **Endpoint:** `POST /api/v1/places/{id}/reviews`
* **Access:** Required (Bearer JWT)
* **Atomic Place Aggregation:** In the same `@Transactional` boundary, the backend recalculates `places.rating` (average score) and `places.review_count`.
* **Uniqueness & Conflict:** A user may only review a given place once (`uq_reviews_user_place`). Submitting a duplicate review returns `409 Conflict` (`DUPLICATE_RESOURCE`).

#### Request Body
```json
{
  "rating": 5,
  "comment": "Wonderful atmosphere and delicious signature coffee!"
}
```

#### Field Constraints:
* `rating`: Integer, required, between `1` and `5` inclusive (`@NotNull`, `@Min(1)`, `@Max(5)`).
* `comment`: String, optional, max 1000 characters (`@Size(max = 1000)`).

#### Response: `201 Created`
```json
{
  "id": "e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55",
  "userId": "a1eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
  "authorName": "Tran Thi B",
  "authorAvatar": "https://res.cloudinary.com/.../avatar.webp",
  "rating": 5,
  "comment": "Wonderful atmosphere and delicious signature coffee!",
  "createdAt": "2026-10-18T11:00:00Z"
}
```

---

## 6. Standard Error Responses

### 6.1. Validation Error (`400 Bad Request`)
```json
{
  "timestamp": "2026-10-18T12:00:00Z",
  "status": 400,
  "code": "VALIDATION_FAILED",
  "message": "Invalid request payload or query parameters.",
  "fieldErrors": {
    "rating": "Rating must be between 1 and 5."
  },
  "path": "/api/v1/places/b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22/reviews",
  "traceId": "req-98f2b31a-4c2e"
}
```

### 6.2. Unauthorized (`401 Unauthorized`)
```json
{
  "timestamp": "2026-10-18T12:00:00Z",
  "status": 401,
  "code": "UNAUTHORIZED",
  "message": "Full authentication is required to access this resource.",
  "path": "/api/v1/itineraries",
  "traceId": "req-1234abcd-56ef"
}
```

### 6.3. Forbidden / Ownership Violation (`403 Forbidden`)
```json
{
  "timestamp": "2026-10-18T12:00:00Z",
  "status": 403,
  "code": "FORBIDDEN_ACCESS",
  "message": "You do not possess permission to access or modify this itinerary.",
  "path": "/api/v1/itineraries/c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
  "traceId": "req-5678efgh-90ij"
}
```

### 6.4. Resource Not Found (`404 Not Found`)
```json
{
  "timestamp": "2026-10-18T12:00:00Z",
  "status": 404,
  "code": "RESOURCE_NOT_FOUND",
  "message": "Itinerary not found with id: c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
  "path": "/api/v1/itineraries/c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
  "traceId": "req-4321dcba-87ba"
}
```

### 6.5. Conflict / Duplicate Resource (`409 Conflict`)
```json
{
  "timestamp": "2026-10-18T12:00:00Z",
  "status": 409,
  "code": "DUPLICATE_RESOURCE",
  "message": "You have already reviewed this place.",
  "path": "/api/v1/places/b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22/reviews",
  "traceId": "req-7777aaaa-1111"
}
```

### 6.6. Rate Limit Exceeded (`429 Too Many Requests`)
```json
{
  "timestamp": "2026-10-18T12:00:00Z",
  "status": 429,
  "code": "RATE_LIMIT_EXCEEDED",
  "message": "Too many requests. Please wait a moment before trying again.",
  "path": "/api/v1/auth/login",
  "traceId": "req-9999xxxx-0000"
}
```
