# Bruno API Testing Collection — Smart Local Planner

> **Tooling:** [Bruno](https://www.usebruno.com/) (Open-Source, lightweight, Git-native API client)  
> **Advantage:** Requests are stored as plain text files directly within the repository. Zero cloud accounts required, zero credential leakage risk, and 100% version-controlled alongside application code.

---

## Usage Instructions

1. **Install Bruno:** Download the desktop client from [https://www.usebruno.com/downloads](https://www.usebruno.com/downloads).
2. **Open the Collection:**
   - Launch Bruno ➔ Click **Open Collection**.
   - Select the `smart-local-planner/bruno/` directory.
3. **Execute Requests:**
   - Ensure the Spring Boot backend is active at `http://localhost:8080`.
   - Select any request below and click **Send**:

| Sequence | Request File | Endpoint & Method | Auth Requirement |
| :---: | :--- | :--- | :--- |
| 1 | `actuator-health.bru` | `GET /actuator/health` | Public |
| 2 | `auth-register.bru` | `POST /api/v1/auth/register` | Public (Rate limited) |
| 3 | `auth-login.bru` | `POST /api/v1/auth/login` | Public (Rate limited) |
| 4 | `auth-refresh-token.bru` | `POST /api/v1/auth/refresh-token` | Public |
| 5 | `auth-logout.bru` | `POST /api/v1/auth/logout` | Bearer `{{accessToken}}` |
| 6 | `places-search.bru` | `GET /api/v1/places` | Public |
| 7 | `favorites-list.bru` | `GET /api/v1/favorites` | Bearer `{{accessToken}}` |
| 8 | `favorites-add.bru` | `POST /api/v1/favorites/{{placeId}}` | Bearer `{{accessToken}}` |
| 9 | `favorites-remove.bru` | `DELETE /api/v1/favorites/{{placeId}}` | Bearer `{{accessToken}}` |
| 10 | `itineraries-list.bru` | `GET /api/v1/itineraries` | Bearer `{{accessToken}}` |
| 11 | `itineraries-create.bru` | `POST /api/v1/itineraries` | Bearer `{{accessToken}}` |
| 12 | `itineraries-get-detail.bru` | `GET /api/v1/itineraries/{{itineraryId}}` | Bearer `{{accessToken}}` |
| 13 | `itineraries-update.bru` | `PUT /api/v1/itineraries/{{itineraryId}}` | Bearer `{{accessToken}}` |
| 14 | `itineraries-delete.bru` | `DELETE /api/v1/itineraries/{{itineraryId}}` | Bearer `{{accessToken}}` |
| 15 | `reviews-list.bru` | `GET /api/v1/places/{{placeId}}/reviews` | Public |
| 16 | `reviews-create.bru` | `POST /api/v1/places/{{placeId}}/reviews` | Bearer `{{accessToken}}` |
