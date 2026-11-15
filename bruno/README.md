# Bruno API Testing Collection — Smart Local Planner

> **Tooling:** [Bruno](https://www.usebruno.com/) (Open-Source, lightweight, Git-native API client)  
> **Structure Standard:** Follows the official `usebruno/bruno` domain-subfolder and environment convention (`environments/` + domain resource folders with automated post-response variable chaining).

---

## 1. Directory Structure

```text
bruno/
├── bruno.json                         # Collection root manifest
├── README.md                          # Usage & request execution order
├── environments/                      # Switchable target environments
│   ├── local.bru                      # http://localhost:8080
│   └── production.bru                 # https://smart-local-planner-api.onrender.com
├── actuator/
│   ├── folder.bru
│   └── health.bru                     # GET /actuator/health
├── auth/
│   ├── folder.bru
│   ├── register.bru                   # POST /api/v1/auth/register (auto-saves tokens)
│   ├── login.bru                      # POST /api/v1/auth/login (auto-saves tokens)
│   ├── refresh-token.bru              # POST /api/v1/auth/refresh-token (auto-rotates tokens)
│   └── logout.bru                     # POST /api/v1/auth/logout
├── places/
│   ├── folder.bru
│   └── search-places.bru              # GET /api/v1/places (auto-saves first placeId)
├── favorites/
│   ├── folder.bru
│   ├── list-favorites.bru             # GET /api/v1/favorites
│   ├── add-favorite.bru               # POST /api/v1/favorites/{{placeId}}
│   └── remove-favorite.bru            # DELETE /api/v1/favorites/{{placeId}}
├── itineraries/
│   ├── folder.bru
│   ├── list-itineraries.bru           # GET /api/v1/itineraries
│   ├── create-itinerary.bru           # POST /api/v1/itineraries (auto-saves itineraryId)
│   ├── get-itinerary-detail.bru       # GET /api/v1/itineraries/{{itineraryId}}
│   ├── update-itinerary.bru           # PUT /api/v1/itineraries/{{itineraryId}}
│   └── delete-itinerary.bru           # DELETE /api/v1/itineraries/{{itineraryId}}
└── reviews/
    ├── folder.bru
    ├── list-reviews.bru               # GET /api/v1/places/{{placeId}}/reviews
    └── create-review.bru              # POST /api/v1/places/{{placeId}}/reviews
```

---

## 2. Quickstart Instructions

1. **Install Bruno:** Download the desktop client from [https://www.usebruno.com/downloads](https://www.usebruno.com/downloads).
2. **Open the Collection:**
   - Launch Bruno ➔ Click **Open Collection**.
   - Select the `smart-local-planner/bruno/` directory.
3. **Select Environment:**
   - In the top-right environment selector, choose **`local`** (`http://localhost:8080`) or **`production`**.
4. **Execute End-to-End Flow (Zero Manual Copy-Paste):**
   - Run `auth/login.bru` (or `auth/register.bru`) ➔ automatically populates `{{accessToken}}` and `{{refreshToken}}`.
   - Run `places/search-places.bru` ➔ automatically populates `{{placeId}}` from the first result.
   - Run `itineraries/create-itinerary.bru` ➔ automatically populates `{{itineraryId}}` for detail, update, and delete requests.

---

## 3. Request Reference Catalog

| Sequence | Request Path | Endpoint & Method | Auth Requirement |
| :---: | :--- | :--- | :--- |
| 1 | `actuator/health.bru` | `GET /actuator/health` | Public |
| 2 | `auth/register.bru` | `POST /api/v1/auth/register` | Public (Rate limited) |
| 3 | `auth/login.bru` | `POST /api/v1/auth/login` | Public (Rate limited) |
| 4 | `auth/refresh-token.bru` | `POST /api/v1/auth/refresh-token` | Public |
| 5 | `auth/logout.bru` | `POST /api/v1/auth/logout` | Bearer `{{accessToken}}` |
| 6 | `places/search-places.bru` | `GET /api/v1/places` | Public |
| 7 | `favorites/list-favorites.bru` | `GET /api/v1/favorites` | Bearer `{{accessToken}}` |
| 8 | `favorites/add-favorite.bru` | `POST /api/v1/favorites/{{placeId}}` | Bearer `{{accessToken}}` |
| 9 | `favorites/remove-favorite.bru` | `DELETE /api/v1/favorites/{{placeId}}` | Bearer `{{accessToken}}` |
| 10 | `itineraries/list-itineraries.bru` | `GET /api/v1/itineraries` | Bearer `{{accessToken}}` |
| 11 | `itineraries/create-itinerary.bru` | `POST /api/v1/itineraries` | Bearer `{{accessToken}}` |
| 12 | `itineraries/get-itinerary-detail.bru` | `GET /api/v1/itineraries/{{itineraryId}}` | Bearer `{{accessToken}}` |
| 13 | `itineraries/update-itinerary.bru` | `PUT /api/v1/itineraries/{{itineraryId}}` | Bearer `{{accessToken}}` |
| 14 | `itineraries/delete-itinerary.bru` | `DELETE /api/v1/itineraries/{{itineraryId}}` | Bearer `{{accessToken}}` |
| 15 | `reviews/list-reviews.bru` | `GET /api/v1/places/{{placeId}}/reviews` | Public |
| 16 | `reviews/create-review.bru` | `POST /api/v1/places/{{placeId}}/reviews` | Bearer `{{accessToken}}` |
