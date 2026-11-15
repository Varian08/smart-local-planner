# Smart Local Planner — Mobile Application (Flutter)

> **Subsystem:** Cross-Platform Mobile Client (Android & iOS)  
> **Architecture:** Feature-First Clean Architecture with `flutter_bloc` State Management  
> **Assigned Engineer:** Mobile Software Engineer (Engineer B)  
> **Reference Specs:** [docs/DEVELOPER_WORKFLOW_PLAYBOOK.md](../docs/DEVELOPER_WORKFLOW_PLAYBOOK.md) | [docs/ARCHITECTURE_BLUEPRINT.md](../docs/ARCHITECTURE_BLUEPRINT.md) | [docs/API_SPECIFICATION.md](../docs/API_SPECIFICATION.md)

---

## 1. Directory Scaffolding (Feature-First Clean Architecture)

The codebase strictly enforces unidirectional 3-tier decoupling:

```text
mobile/
├── AGENTS.md                       # Mobile-scoped AI engineering rules
├── PRODUCT.md                      # Durable product context & scope boundaries (impeccable schema)
├── DESIGN.md                       # Material 3 design system tokens & component rules
├── lib/
│   ├── main.dart                   # Application entrypoint, Root MultiBlocProvider & Material 3 seed theme
│   ├── core/                       # Shared modules across features
│   │   ├── constants/              # ApiEndpoints & timeout constants
│   │   ├── network/                # DioClient & AuthInterceptor (QueuedInterceptor 401 rotation)
│   │   ├── storage/                # SecureStorageService (Sprint 2 - Keystore/Keychain)
│   │   └── utils/                  # AuthGuard (guest-to-authenticated action gating)
│   └── features/                   # Feature-first vertical slices
│       ├── places/                 # Place Discovery, Search & PlaceDetailScreen (Sprint 1–3 Complete)
│       │   ├── data/               # PlaceRepository, PlaceModel, PageResponse
│       │   ├── bloc/               # PlaceBloc, PlaceEvent, PlaceState (Concurrency Hardened)
│       │   └── presentation/       # PlaceListScreen, PlaceDetailScreen, PlaceCard
│       ├── auth/                   # Registration, Login, Session Management (Sprint 2 Complete)
│       ├── favorites/              # Personal Bookmarks & FavoriteListScreen (Sprint 2 Complete)
│       ├── itineraries/            # Multi-day Travel Itinerary CRUD & Day Timeline (Sprint 3 Complete)
│       └── reviews/                # Place Reviews, StarRatingWidget & ReviewFormBottomSheet (Sprint 3 Complete)
├── test/                           # Unit, BLoC, and Widget Test Suites (136 tests)
└── README.md
```

---

## 2. Architectural Invariants (Non-Negotiable Rules)

1. **Mandatory 4-State UI Contract:**
   Every data-driven screen must explicitly handle 4 distinct lifecycle states:
   * `LoadingState`: Non-blocking skeleton/shimmer loader (never lock the entire screen).
   * `SuccessState`: Content successfully populated.
   * `ErrorState`: Actionable error message with a dedicated **Retry Action** button.
   * `EmptyState`: Friendly empty-state artwork and descriptive hint when data list length is 0.
2. **Zero Direct Network Invocations from Widgets:**
   - Presentation widgets (`presentation/`) only dispatch events (`add(Event)`).
   - `Bloc` processes events and invokes methods on `Repository`.
   - `Repository` handles serialization and interacts via `DioClient`.
   - Direct `Dio.get()` or `http.get()` calls inside widgets are strictly prohibited.
3. **Hardware-Backed Token Security:**
   - Access and Refresh tokens **must** reside in `flutter_secure_storage` (AES-256 Android Keystore / iOS Keychain).
   - Storing authentication tokens in plaintext `SharedPreferences` is strictly prohibited.

---

## 3. Local Backend Connectivity Guide

When running the Spring Boot backend on the host machine (`http://localhost:8080`), configure the base URL according to the mobile runtime target:

| Runtime Environment | Backend Target URL | Technical Note |
| :--- | :--- | :--- |
| **Android Emulator** | `http://10.0.2.2:8080/api/v1` | IP `10.0.2.2` is the loopback alias to the host machine |
| **iOS Simulator** | `http://localhost:8080/api/v1` | iOS Simulator shares the host network stack natively |
| **Physical Device (via Wi-Fi)** | `http://<HOST_LAN_IP>:8080/api/v1` | Both workstation and phone must connect to the same Wi-Fi subnet (e.g., `http://192.168.1.15:8080/api/v1`) |

---

## 4. Getting Started & Execution Guide

### Prerequisites
- **Flutter SDK:** `>= 3.13.7` (`flutter --version`)
- **Target Platform:** Google Chrome, Android Emulator, iOS Simulator, or a physical mobile device.

### Step 1: Install Dependencies & Verify Environment
From the `mobile/` directory:
```bash
flutter pub get
flutter doctor
```

### Step 2: Local Quality Gates (Pre-Commit Verification)
Always verify the test suite and static analysis before pushing changes:
```bash
# Run unit & BLoC tests
flutter test

# Run static lint analysis (must report 0 issues)
flutter analyze
```

### Step 3: Run the Application

| Target Environment | Execution Command | Connectivity Note |
| :--- | :--- | :--- |
| **Web Browser (Chrome)** | `flutter run -d chrome` | Connects directly to `http://localhost:8080/api/v1` |
| **Web Browser (Edge)** | `flutter run -d edge` | Pre-installed native browser on Windows, zero extra setup |
| **Android Emulator** | `flutter run -d android` | Auto-resolves `http://10.0.2.2:8080/api/v1` via `ApiEndpoints` |
| **iOS Simulator** | `flutter run -d ios` | Connects to `http://localhost:8080/api/v1` |
| **Physical Device (USB/Wi-Fi)** | `flutter run --dart-define=API_BASE_URL=http://<HOST_LAN_IP>:8080/api/v1` | Explicitly overrides backend host IP for local Wi-Fi subnet |

> [!NOTE]
> **Windows Desktop vs. Mobile & Web Execution:**  
> Running `flutter run -d windows` attempts to build a native Windows desktop executable (`.exe`), which requires the heavy Microsoft Visual Studio 2022 C++ desktop toolchain (~15GB). Because Smart Local Planner is designed specifically as a cross-platform mobile client, building for Windows desktop is **not required**. Always execute against **Web (`-d chrome` / `-d edge`)**, an **Android Studio Virtual Device (`-d android`)**, or a **physical mobile device via USB debugging**.

---

## 5. Mobile Engineering Roadmap

* **Sprint 0 (Foundation - Completed):** Establish application skeleton, configure Dio client with `AuthInterceptor`, establish Material 3 theme tokens, and scaffold directory structure.
* **Sprint 1 (The First Vertical Slice - Completed):** Implement Place Discovery screen (`PlaceListScreen`), integrate infinite scroll pagination, render Cloudinary-optimized images, and enforce the 4-state UI contract.
* **Sprint 2 (Authentication & Favorites - Completed):** Integrate registration/login screens, secure token storage lifecycle, and implement Bookmark/Favorite toggling.
* **Sprint 3 (Itineraries & Reviews - Completed):** Implement `ItineraryBloc`, `ItineraryListScreen`, `ItineraryDetailScreen` day-by-day timeline, `CreateItineraryDialog`, `PlaceDetailScreen`, scoped `ReviewBloc`, `ReviewFormBottomSheet` with inline conflict banner, and `PRODUCT.md` / `DESIGN.md` specs.
* **Sprint 4 (Cloud Release & Production Polish - Active / Next):** Centralize `DESIGN.md` tokens into `lib/core/theme/`, add pre-refresh token double-check in `AuthInterceptor`, integrate Cloudinary media flows, and package release `.apk` artifacts.
