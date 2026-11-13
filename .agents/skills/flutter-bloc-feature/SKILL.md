---
name: flutter-bloc-feature
description: >-
  Use when implementing or modifying Flutter features under mobile/lib/features/,
  including repositories, BLoCs, screens, bottom sheets, or widget/BLoC tests.
---

# Flutter BLoC Feature Workflow

Follow this procedure when building or updating any feature under `mobile/lib/features/` to keep UI, state preservation, and design tokens consistent.

## Steps

1. **Load Product, Design & Framework Context:**
   - Read `mobile/PRODUCT.md` and `mobile/DESIGN.md` before designing or editing widgets.
   - Consult **Dart and Flutter** MCP and **Context7** (`flutter_bloc`, `dio`) when introducing new BLoC concurrency patterns, `Dio` interceptors, or plugins.

2. **Structure Layers & Choose BLoC Scope:**
   - Partition code into `data/models/`, `data/repositories/`, `bloc/` (`*_bloc.dart`, `*_event.dart`, `*_state.dart`), and `presentation/screens/` + `presentation/widgets/`.
   - Never call `DioClient` directly from widgets or screens.
   - **Scoped vs. Global Provider:** Only place app-wide state in root `MultiBlocProvider` (`mobile/lib/main.dart`). Use a route-scoped `BlocProvider` (accepting an optional injected test BLoC, like `PlaceDetailScreen`) for screen-specific or modal workflows (`ReviewBloc`).

3. **Preserve State & Render Modal Errors Inline:**
   - Carry currently loaded items (`currentItems`) inside `*Submitting` and `*Failure` states so lists never flash empty or vanish when a mutation fails (pattern: `ReviewBloc._extractCurrentReviews()`).
   - When an error occurs while a bottom sheet or dialog is open, show an inline error banner inside the modal instead of relying solely on background `SnackBar`.
   - Disable primary action buttons and show an inline spinner during pending requests to block duplicate taps.

4. **Implement 4-State UI & Design Compliance:**
   - Handle **Loading**, **Success**, **Empty** (with primary CTA), and **Error** (with actionable Retry) on every data view.
   - Apply palette, typography, radii, and elevation tokens from `mobile/DESIGN.md`.
   - Guard all text with `maxLines` + `TextOverflow.ellipsis` and wrap scrollable forms/sheets with `SingleChildScrollView` + `MediaQuery.of(context).viewInsets.bottom`.

5. **Write Tests & Verify Quality Gates:**
   - Mirror tests under `mobile/test/features/<feature>/`: model JSON edge cases, repository HTTP error mapping, BLoC state transitions + failure preservation, and widget tests covering all 4 states and disabled loading state.
   - Run `Set-Location mobile; flutter analyze` (expect `No issues found!`) and `flutter test` (expect all tests pass).

