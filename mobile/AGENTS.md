# Mobile Engineering Rules (`mobile/`)

> Scope: Applies to all Flutter/Dart files under `mobile/`. Inherits monorepo rules from root [AGENTS.md](../AGENTS.md). Read [PRODUCT.md](PRODUCT.md) and [DESIGN.md](DESIGN.md) before modifying or creating any UI.

---

## 1. Stack & Verification

- **Stack:** Flutter (CI pinned `3.47.8`), Dart `^3.13.7`, `flutter_bloc ^9.1.1`, `bloc_concurrency ^0.3.0`, `dio ^5.11.1`, `equatable ^3.0.0`, `cached_network_image ^4.0.5`, `flutter_secure_storage ^9.2.2`, `flutter_lints ^6.0.0`.
- **Verification Gate (must be green before committing):**
  - `Set-Location mobile; flutter analyze` -> `No issues found!`
  - `flutter test` -> All tests pass.
- **Tools:** Consult **Dart and Flutter** MCP and **Context7** (`flutter_bloc`, `dio`) when building new state flows, navigation, or image upload clients. Use the `impeccable` skill for UI design audits and polish.

---

## 2. Feature-First BLoC Architecture

1. **Directory Boundaries (`lib/features/<feature>/`):**
   - `data/models/`: Typed models with defensive `fromJson`/`toJson` parsing; never crash on nullable optional JSON fields.
   - `data/repositories/`: Interfaces + `DioClient` implementations. Widgets and screens must **never** call `DioClient` directly.
   - `bloc/`: Unidirectional `Event -> Bloc -> State` with `Equatable` value equality.
   - `presentation/screens/` & `presentation/widgets/`: Prefer `StatelessWidget`; render strictly from state and dispatch events.
2. **Scoped vs. Global BLoC Providers:**
   - Root `MultiBlocProvider` in `lib/main.dart` owns only cross-app state (`AuthBloc`, `PlaceBloc`, `FavoriteBloc`, `ItineraryBloc`).
   - Detail-scoped or modal workflows (like `ReviewBloc` in `PlaceDetailScreen`) **must** use a route-scoped `BlocProvider` (`create:` per screen instance, with optional injected test BLoC) so state never leaks across different destinations.
3. **State Preservation on Mutation Errors:**
   - Submitting and failure states (`*Submitting`, `*Failure`) must carry the currently loaded list/data (`currentItems` — see `ReviewBloc._extractCurrentReviews()`) so failed mutations (`409 Conflict`, validation error, timeout) never wipe visible screen content or cause blank flashes.
4. **Network & Token Refresh Safety (`lib/core/network/auth_interceptor.dart`):**
   - Keep JWT refresh logic serialized inside `QueuedInterceptor`. When adding retry/refresh logic, double-check whether `SecureStorageService` already holds a newer access token rotated by an earlier queued request before calling `/auth/refresh-token` again.

---

## 3. UI/UX, Error Display & Accessibility Contract

1. **Mandatory 4-State UI:** Every data-driven screen handles:
   - **Loading:** Skeleton cards or non-blocking progress indicator.
   - **Success:** Populated content with pull-to-refresh where appropriate.
   - **Empty:** Descriptive empty state with a primary action button (e.g. Explore Places / Create Trip).
   - **Error:** Clear error view with an actionable **Retry** button.
2. **Bottom Sheets & Modals:** When a modal bottom sheet or dialog is open, render mutation/validation errors **inline inside the sheet**—do not rely only on background `ScaffoldMessenger.of(context).showSnackBar(...)`, which gets obscured behind the sheet.
3. **Mobile Edge Cases Checklist:**
   - **Virtual Keyboard:** Wrap forms and bottom sheets in `SingleChildScrollView` with `MediaQuery.of(context).viewInsets.bottom` padding to avoid `RenderFlex overflowed`.
   - **Text Truncation:** Apply `maxLines` + `TextOverflow.ellipsis` on variable-length titles, addresses, and notes.
   - **Double-Tap Prevention:** Disable submit buttons and show an inline spinner during in-flight requests.
   - **Auth Gating:** Route unauthenticated protected taps (`bookmark`, `create trip`, `write review`) through `AuthGuard` without discarding screen context.
4. **Design System Compliance:** Match palette, radii, spacing, and typography tokens in [DESIGN.md](DESIGN.md); avoid introducing arbitrary one-off colors when an equivalent token exists.

---

## 4. Testing Requirements

Maintain unit and widget tests under `mobile/test/` mirroring `lib/` structure:
- **Models & Repositories:** JSON serialization edge cases (nulls, empty lists) and HTTP error mapping.
- **BLoCs:** State transitions (`Initial -> Loading -> Loaded/Failure`), state preservation during mutation errors, and concurrency edge cases.
- **Screens & Widgets:** Render all 4 states, button disabled while submitting, inline validation/error messages, and navigation triggers.

