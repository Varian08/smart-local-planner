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
  "expiresIn": 1800
}
```

---

### 1.4. Logout Session
* **Endpoint:** `POST /api/v1/auth/logout`
* **Access:** Required (`Authorization: Bearer <access_token>`)

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
  "isFavorite": false
}
```

---

## 3. Favorites Domain (`/api/v1/favorites`)

### 3.1. List User Favorites
* **Endpoint:** `GET /api/v1/favorites`
* **Access:** Required

#### Response: `200 OK`
```json
[
  {
    "id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
    "name": "The Coffee House - Landmark 81",
    "category": "CAFE",
    "address": "Floor B1, Landmark 81, Binh Thanh District, HCMC",
    "imageUrl": "https://res.cloudinary.com/smartplanner/image/upload/v1/landmark.webp",
    "averageRating": 4.6,
    "savedAt": "2026-10-18T09:15:00Z"
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
* **Access:** Required

#### Response: `200 OK`
```json
[
  {
    "id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
    "title": "Weekend in Saigon Highlights",
    "description": "2-day discovery of iconic landmarks and coffee culture.",
    "startDate": "2026-10-24",
    "endDate": "2026-10-25",
    "totalDays": 2,
    "totalPlaces": 4,
    "isPublic": false,
    "createdAt": "2026-10-18T08:00:00Z"
  }
]
```

---

### 4.2. Create Itinerary
* **Endpoint:** `POST /api/v1/itineraries`
* **Access:** Required

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

#### Response: `201 Created`
```json
{
  "id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
  "title": "Weekend in Saigon Highlights",
  "totalDays": 2,
  "createdAt": "2026-10-18T08:00:00Z"
}
```

---

### 4.3. Get Itinerary Detail with Schedule
* **Endpoint:** `GET /api/v1/itineraries/{id}`
* **Access:** Required + Owner (or Public if `isPublic == true`)

#### Response: `200 OK`
```json
{
  "id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
  "title": "Weekend in Saigon Highlights",
  "description": "2-day discovery of iconic landmarks and coffee culture.",
  "startDate": "2026-10-24",
  "endDate": "2026-10-25",
  "isPublic": false,
  "days": [
    {
      "dayNumber": 1,
      "date": "2026-10-24",
      "items": [
        {
          "id": "d3eebc99-9c0b-4ef8-bb6d-6bb9bd380a44",
          "orderIndex": 0,
          "startTime": "09:00:00",
          "notes": "Morning coffee meeting",
          "place": {
            "id": "b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22",
            "name": "The Coffee House - Landmark 81",
            "address": "Floor B1, Landmark 81, Binh Thanh District, HCMC",
            "category": "CAFE",
            "imageUrl": "https://res.cloudinary.com/.../landmark.webp"
          }
        }
      ]
    }
  ]
}
```

---

### 4.4. Update Itinerary
* **Endpoint:** `PUT /api/v1/itineraries/{id}`
* **Access:** Required + Owner

#### Request Body
```json
{
  "title": "Updated Saigon 3-Day Trip",
  "description": "Extended trip including culinary exploration.",
  "startDate": "2026-10-24",
  "endDate": "2026-10-26",
  "isPublic": true,
  "items": [ ... ]
}
```

#### Response: `200 OK`
```json
{
  "id": "c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33",
  "title": "Updated Saigon 3-Day Trip",
  "updatedAt": "2026-10-18T10:30:00Z"
}
```

---

### 4.5. Delete Itinerary
* **Endpoint:** `DELETE /api/v1/itineraries/{id}`
* **Access:** Required + Owner

#### Response: `204 No Content`

---

## 5. Reviews Domain (`/api/v1/places/{id}/reviews`)

### 5.1. List Reviews for Place
* **Endpoint:** `GET /api/v1/places/{id}/reviews`
* **Access:** Public

#### Response: `200 OK`
```json
[
  {
    "id": "e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55",
    "authorName": "Tran Thi B",
    "authorAvatar": "https://res.cloudinary.com/.../avatar.webp",
    "rating": 5,
    "comment": "Wonderful atmosphere and delicious signature coffee!",
    "createdAt": "2026-10-15T14:20:00Z"
  }
]
```

---

### 5.2. Submit Review
* **Endpoint:** `POST /api/v1/places/{id}/reviews`
* **Access:** Required

#### Request Body
```json
{
  "rating": 5,
  "comment": "Wonderful atmosphere and delicious signature coffee!"
}
```

#### Response: `201 Created`
```json
{
  "id": "e4eebc99-9c0b-4ef8-bb6d-6bb9bd380a55",
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
  "message": "Input validation error occurred.",
  "fieldErrors": {
    "rating": "Rating must be an integer between 1 and 5."
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
  "path": "/api/v1/favorites",
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

### 6.4. Rate Limit Exceeded (`429 Too Many Requests`)
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
