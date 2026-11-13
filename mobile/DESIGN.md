---
name: Smart Local Planner
description: Material 3 travel discovery and multi-day itinerary UI anchored by Indigo structure, crisp white cards, and warm Amber rating cues.
colors:
  primary: "#3F51B5"
  primary-soft: "#E8EAF6"
  primary-deep: "#1A237E"
  accent-review: "#009688"
  accent-review-soft: "#E0F2F1"
  accent-review-deep: "#00695C"
  rating: "#FFC107"
  rating-soft: "#FFF8E1"
  rating-border: "#FFE082"
  rating-deep: "#FF8F00"
  price-green: "#4CAF50"
  success: "#388E3C"
  danger: "#D32F2F"
  danger-soft: "#FFEBEE"
  danger-border: "#EF9A9A"
  favorite-heart: "#FF5252"
  surface: "#FFFFFF"
  scaffold: "#FAFAFA"
  surface-muted: "#F5F5F5"
  surface-skeleton: "#EEEEEE"
  border: "#E0E0E0"
  text-primary: "#212121"
  text-body: "#424242"
  text-secondary: "#757575"
  text-muted: "#9E9E9E"
typography:
  display:
    fontFamily: "Roboto, sans-serif"
    fontSize: "32px"
    fontWeight: 700
    lineHeight: 1.2
  headline:
    fontFamily: "Roboto, sans-serif"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: 1.25
  title-lg:
    fontFamily: "Roboto, sans-serif"
    fontSize: "22px"
    fontWeight: 700
    lineHeight: 1.3
  title-md:
    fontFamily: "Roboto, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.35
  card-title:
    fontFamily: "Roboto, sans-serif"
    fontSize: "17px"
    fontWeight: 700
    lineHeight: 1.35
  body:
    fontFamily: "Roboto, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.45
  button:
    fontFamily: "Roboto, sans-serif"
    fontSize: "16px"
    fontWeight: 600
    lineHeight: 1.25
  caption:
    fontFamily: "Roboto, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.35
  micro:
    fontFamily: "Roboto, sans-serif"
    fontSize: "11px"
    fontWeight: 700
    lineHeight: 1.2
rounded:
  handle: "2px"
  sm: "8px"
  md: "10px"
  lg: "12px"
  xl: "16px"
  card: "20px"
  sheet: "24px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  base: "16px"
  lg: "20px"
  xl: "24px"
  2xl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "16px 24px"
  button-review:
    backgroundColor: "{colors.accent-review}"
    textColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "14px 20px"
  card-place:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.card}"
    padding: "16px"
  input-field:
    backgroundColor: "{colors.surface-muted}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.lg}"
    padding: "14px"
  chip-filter:
    backgroundColor: "{colors.primary-soft}"
    textColor: "{colors.primary-deep}"
    rounded: "{rounded.card}"
    padding: "6px 12px"
---

# Design System: Smart Local Planner

## Overview

**Creative North Star: "The Calm Field Guide"**

Smart Local Planner adopts a clean, light-first Material 3 visual language inspired by sunlit editorial travel cards. Crisp white surfaces (`#FFFFFF`) sit over a soft warm-grey canvas (`#FAFAFA`), giving photography, place ratings, and multi-day itinerary timelines breathing room without visual noise.

Indigo (`Colors.indigo`) leads navigation, search icons, trip routes, and primary actions, while Teal (`Colors.teal`) distinguishes community review interactions and Amber (`Colors.amber`) isolates ratings and traveler tips.

**Key Characteristics:**
- Light-first Material 3 (`useMaterial3: true`, `colorSchemeSeed: Colors.indigo`) with `scaffoldBackgroundColor: Colors.grey.shade50` (`#FAFAFA`).
- Generous card geometry (`20px` outer card radius paired with soft `elevation: 1–2` shadows).
- Clear 4-state scaffolding (`Loading` skeletons, `Success`, `Empty` with soft-tinted icon badge + primary CTA, `Error` with outlined Retry).

## Colors

A restrained functional palette where color encodes domain meaning rather than decoration.

### Primary
- **Indigo Field (`#3F51B5` / `Colors.indigo`)**: Primary app bar icons, itinerary indicators, FAB (`FloatingActionButton.extended`), day selector active fill, focused actions, and primary `FilledButton` via Material 3 `colorSchemeSeed`.
- **Indigo Tint (`#E8EAF6` / `Colors.indigo.shade50`)**: Empty-state icon halo, selected category chip fill, and itinerary card header icon badge.
- **Indigo Ink (`#1A237E` / `Colors.indigo.shade900`)**: Text inside selected light Indigo filter chips.

### Secondary
- **Teal Community (`#009688` / `Colors.teal`)**: Review submission button (`ElevatedButton`), write-review outlined CTA, focused review input border, and reviewer avatar pill (`shade100` / `shade900`).
- **Teal Category Badge (`#E0F2F1` / `Colors.teal.shade50` + `#00695C` text)**: Category pill in `PlaceDetailScreen` and duration pill in `ItineraryCard`.

### Semantic Signals
- **Amber Star & Tip (`#FFC107` / `Colors.amber`)**: Star icons (`StarRatingWidget`), rating summary box (`shade50` at 50% alpha with `shade100` border), and itinerary stop notes (`shade50` background + `Brown shade800` `#4E342E` text).
- **Price Green (`#4CAF50` / `Colors.green`) & Success Toast (`#388E3C`)**: `₫` price level indicator and confirmation SnackBars.
- **Favorite Coral (`#FF5252` / `Colors.redAccent`) & Error Red (`#D32F2F` / `Colors.red.shade700`)**: Active bookmark heart, delete triggers, error banners (`shade50` background + `shade200` border), and failure feedback.

### Neutral
- **Pure Card White (`#FFFFFF`)**: `AppBar` background (`elevation: 0`), `PlaceCard`, `ItineraryCard`, `PlaceDetailScreen` body, `ReviewFormBottomSheet`.
- **Mist Canvas (`#FAFAFA` / `Colors.grey.shade50`)**: Root scaffold background behind cards and empty review box.
- **Soft Fill (`#F5F5F5` / `Colors.grey.shade100`)**: Search bar fill, unselected filter chips, fallback image containers.
- **Skeleton / Divider (`#EEEEEE` / `Colors.grey.shade200`) & Border (`#E0E0E0` / `Colors.grey.shade300`)**: Loading shimmer blocks, list dividers, unselected stars, and default `OutlineInputBorder`.
- **Typography Ink Scale**: `#212121` (`Colors.black87`) headings, `#424242` (`Colors.grey.shade800`) descriptions/comments, `#757575` (`Colors.grey.shade600`) metadata, `#9E9E9E` (`Colors.grey.shade500`) muted dates/counts.

### Named Rules
**The Semantic Signal Rule.** Reserve `Amber` strictly for star ratings and traveler note callouts, `Teal` for community review workflows, and `Indigo` for discovery navigation and itineraries. Never swap accent hues arbitrarily across unrelated domains.

## Typography

**Display & Body Font:** Default Material 3 `Roboto` (sans-serif platform stack) driven by `Theme.of(context).textTheme` with explicit weight/size emphasis where clarity demands it.

**Character:** Compact, bold headings (`FontWeight.bold`, negative `-0.5` letter-spacing on AppBar brand titles) paired with neutral 13–14px body text for rapid scanning on mobile screens.

### Hierarchy
- **Display Metric** (700, `32px`, `1.2`): Aggregate star rating hero number (`review_list_widget.dart`).
- **Headline** (700, `24px`, `1.25`): Destination name on `PlaceDetailScreen` (`headlineSmall` on Auth screens).
- **Title Large** (700, `22px`, `1.3`): Itinerary detail title and empty-state headings (`titleLarge`).
- **Title Medium** (700, `18px`, `1.35`): Section titles ("About", "Reviews"), modal bottom-sheet titles, error headings.
- **Card Title** (700, `17px`, `1.35`): Place name on `PlaceCard` (`titleMedium` on `ItineraryCard`).
- **Body** (400, `14px`, `1.45`; `13px` compact): Descriptions, addresses, review comments (`bodyMedium` / `#424242`).
- **Button** (600–700, `16px`, `1.25`): Primary `FilledButton` and review `ElevatedButton` labels.
- **Label / Caption** (500–600, `12px`, `1.35`): Metadata chips, reviewer dates, subtle counters.
- **Micro Badge** (700, `11px`, `1.2`): Uppercase category pills (`CULTURE`, `FOOD`).

## Layout

- **Page Gutters:** Standard list/detail horizontal margin is `16px` (`EdgeInsets.symmetric(horizontal: 16, vertical: 12)`), expanding to `20px` on `PlaceDetailScreen` content and `24px` inside auth screens, `CreateItineraryDialog`, and centered Empty/Error states.
- **Card Cadence:** Cards carry `16px` internal padding (`14px` on timeline stop cards) with `12px` vertical spacing between timeline items and `16px` between summary sections.
- **Scrolling & Keyboard Safety:** Feeds rely on `ListView` / `CustomScrollView` (`SliverAppBar` `260px` expanded hero). Forms and bottom sheets wrap content in `SingleChildScrollView` and add `MediaQuery.of(context).viewInsets.bottom` bottom padding.

## Elevation & Depth

Surfaces stay **flat-by-default** at the chrome tier and rely on subtle elevation (`1–2 dp`) plus crisp hairline borders (`1px`) rather than heavy drop shadows.

- **Chrome (`elevation: 0`):** `AppBar` sits flush in `#FFFFFF` over `#FAFAFA` or scrollable body.
- **Content Cards (`elevation: 1–2`, `shadowColor: Colors.black12`):** `PlaceCard`, `ItineraryCard`, and `ItineraryDetailScreen` timeline/header cards lift gently off `#FAFAFA`.
- **Tonal Containment (`border: 1px solid`, `elevation: 0`):** Category tags, metadata pills, rating boxes (`amber.shade100`), error boxes (`red.shade200`), and empty review cards (`grey.shade200`) communicate grouping via soft tinted fills + `1px` borders.

## Shapes

A soft, approachable pill-and-card geometry keeps corners proportional to container scale:
- **Drag Handle:** `2px` (`review_form_bottom_sheet`)
- **Metadata Badges & Date Buttons:** `8px`–`10px`
- **Inputs, Search, Standard Buttons, Thumbnails:** `12px` (`16px` on `PlaceListScreen` search field)
- **Dialogs, Filter Chips & Feature Cards:** `20px`
- **Modal Bottom Sheets:** `24px` top corners (`BorderRadius.vertical(top: Radius.circular(24))`)

## Components

### Buttons
- **Shape:** `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))` (pill `20px` for `write_review_button` outlined CTA).
- **Primary (`FilledButton`):** Seed Indigo (`#3F51B5`), `#FFFFFF` bold/semibold `16px` text, `vertical: 16` (`12px` in empty-state CTAs).
- **Review Submit (`ElevatedButton`):** Solid Teal (`#009688`), `#FFFFFF` text, `elevation: 0`, `vertical: 14`, inline `CircularProgressIndicator` while submitting.
- **Secondary / Retry (`OutlinedButton.icon`):** `12px` radius for error retry and date pickers; `20px` pill border in Teal for review prompt.

### Chips & Metadata Badges
- **Filter Chips (`ChoiceChip`):** `20px` radius; selected `#E8EAF6` bg + `#3F51B5` border + `#1A237E` bold text; unselected `#F5F5F5` bg + `#E0E0E0` border.
- **Day Filter Chips (Itinerary):** `18px` skeleton / pill chip; active solid `#3F51B5` with `#FFFFFF` bold label.
- **Metadata Pills:** `8px` radius, `shade50` fill + `shade200` `1px` border + `14px` icon + `12px` `shade900` text.

### Cards (`PlaceCard` & `ItineraryCard`)
- **Corner Style:** `20px` rounded rectangle (`16px` on nested timeline step cards).
- **PlaceCard Media:** Full-bleed top image with dark translucent overlays (`Colors.black` at `0.65` alpha for category tag `r=12`, `0.4` alpha for circular heart favorite toggle), plus `#F5F5F5` fallback placeholder on load error.
- **Itinerary Timeline Card:** `14px` padding, `#3F51B5` numbered index badge (`#FFFFFF` bold text), `10px`-rounded thumbnail, optional Amber note callout (`r=8`).

### Inputs & Modals
- **Text Fields:** `12px` radius (`16px` search bar with `#F5F5F5` fill), `#E0E0E0` default border, `#009688` `1.5px` focus border in review form, `14px` content padding.
- **Dialogs (`CreateItineraryDialog`):** `20px` rounded card, `24px` padding, Indigo icon badge (`r=10`).
- **Bottom Sheets (`ReviewFormBottomSheet`):** White surface, `24px` top radius, centered `2px` grey handle, keyboard-aware bottom padding.

## Do's and Don'ts

### Do:
- **Do** implement all 4 states (Loading skeleton, Success, Empty with CTA, Error with Retry) on every data screen.
- **Do** display mutation errors **inline inside open dialogs and bottom sheets** so active user input and existing background lists stay visible (`SnackBar` alone sits behind modal sheets).
- **Do** preserve `TextOverflow.ellipsis` and bounded `maxLines` on place names, addresses, and trip titles.
- **Do** use `Theme.of(context).colorScheme` alongside `DESIGN.md` tokens when authoring new Sprint 4 components.

### Don't:
- **Don't** introduce arbitrary uncoordinated colors (e.g., random oranges, purples outside trip metadata, or pure `#000000` shadows/text) when an existing token covers the role.
- **Don't** wipe previously loaded reviews, places, or itineraries when a submit/delete mutation fails (`409 Conflict` / timeout).
- **Don't** leave interactive buttons active while a submission is in flight; swap to a progress indicator or disabled state immediately.
- **Don't** allow virtual keyboards inside bottom sheets or dialogs to trigger `RenderFlex overflowed`.

