# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

- **Travelers (Guest mode):** Visitors browsing curated local destinations by keyword, category, price tier, and community ratings without signing in first.
- **Authenticated Travelers:** Signed-in users who bookmark favorite places, organize multi-day personal travel itineraries with day-by-day place stops, and publish place reviews.

## Product Purpose

Smart Local Planner helps travelers discover verified local points of interest (dining, sightseeing, culture, entertainment) and convert them into structured, multi-day personal trip plans on mobile without juggling scattered notes or spreadsheets.

Success means a user can explore destinations quickly as a guest, seamlessly sign in when saving a favorite or building an itinerary, keep personal trip timelines organized day by day, and read/submit trustworthy community ratings.

## Positioning

Smart Local Planner is an open-architecture, `$0`-infrastructure travel companion focused strictly on verified database-backed place discovery, structured multi-day itinerary planning, and hardware-encrypted session security (`FlutterSecureStorage`). It intentionally avoids social feed clutter, peer chat, payment gateways, and ungrounded AI text generation.

## Operating Context

- Cross-platform Flutter 3 client (`mobile/`) communicating exclusively with the Spring Boot 3.3 REST API (`/api/v1`) and loading destination photography from Cloudinary CDN (`CachedNetworkImage`).
- Targets Android (and iOS via shared Material 3 codebase; release APK packaging is planned in Sprint 4).
- Designed for variable mobile connectivity and cold-start backend latency (~30–50s on free-tier PaaS), requiring clear loading skeletons, actionable retry controls, and persistent token rotation via `Dio` `QueuedInterceptor`.
- All protected user flows (`favorites`, `itineraries`, `submit review`) gate gracefully through `AuthGuard` without breaking guest discovery.

## Capabilities and Constraints

- **Implemented capabilities (Sprints 0–3):**
  - Authentication: Register, login, JWT Access Token (30m) + Refresh Token (7d) rotation, logout (`flutter_secure_storage`).
  - Place Discovery: Paginated infinite scroll list, keyword query, category filter chips (`FilterChip`/`ChoiceChip`), min-rating & price filtering, full detail view (`PlaceDetailScreen`).
  - Favorites: Bookmark toggle on cards/detail screens and dedicated `FavoriteListScreen`.
  - Multi-Day Itineraries: Create/update/delete trip plans, multi-day horizontal day filter chips, day-by-day scheduled stop timeline (`ItineraryDetailScreen`).
  - Community Reviews: Public review summary & list, 1–5 interactive star picker (`ReviewFormBottomSheet`), and backend duplicate-review conflict protection (`409 Conflict`).
- **Planned Sprint 4 scope (not yet shipped):** Image upload integration with Cloudinary CDN and cloud production deployment (Neon PostgreSQL + Render.com).
- **Explicit non-goals (`docs/ARCHITECTURE_BLUEPRINT.md §1.3`):** No payment gateways (Stripe/VNPay/MoMo), no real-time chat/WebSockets, no follower graphs, no automated web scraping.
- **UI copy assumption (`[Inferred from codebase — confirm with team]`):** All implemented screens and validation messages are currently in English; `flutter_localizations` / Vietnamese i18n is not configured yet.

## Brand Commitments

- **Product Name:** Smart Local Planner.
- **Visual Identity:** Clean Material 3 travel utility anchored by `Indigo` primary navigation/itinerary cues, `Teal` review actions, `Amber` rating signals, and bright card-based scannability (`mobile/DESIGN.md`).
- **Truthfulness Constraint:** Never fabricate user reviews, external booking guarantees, or production metrics.

## Evidence on Hand

- Product & API specifications: `docs/ARCHITECTURE_BLUEPRINT.md`, `docs/API_SPECIFICATION.md`, `docs/DEVELOPMENT_GUIDELINES.md`, and `bruno/` request collections.
- Automated verification suite: `mobile/test/` (BLoC, repository, model, network, and widget tests) and `backend/src/test/`.
- Note: Project is in greenfield pre-production; no live user analytics, production telemetry, or customer testimonials exist yet.

## Product Principles

1. **Contract-First Reliability:** Every mobile model, request payload, and screen state maps strictly to `docs/API_SPECIFICATION.md`.
2. **Respect Every State:** Loading, Success, Empty (with clear next action), and Error (with Retry) are mandatory on all data screens.
3. **Never Wipe User Context on Failure:** Mutation errors (such as `409 Conflict` on review submit or transient network timeouts) must preserve loaded screen lists and surface clear inline feedback.
4. **Browse First, Authenticate on Action:** Let travelers inspect places and reviews freely before asking them to sign in.

## Accessibility & Inclusion

- `[Baseline target — pending formal device audit]`: Preserve minimum 48×48 dp touch targets on interactive icons/chips, legible contrast on `#FFFFFF` and `#FAFAFA` surfaces, virtual-keyboard-safe scrolling forms (`viewInsets.bottom`), text truncation with ellipsis (`TextOverflow.ellipsis`), and non-crashing fallbacks for failed image loads.

