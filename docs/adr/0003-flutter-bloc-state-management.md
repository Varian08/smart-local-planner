# 0003. Flutter BLoC Pattern for Presentation State Isolation

- Date: 2026-10-17
- Status: accepted
- Deciders: Engineer B (Mobile)

## Context

The Mobile application requires a predictable, scalable state management solution to handle asynchronous network requests, offline cache fallbacks, authentication states, and UI screen transitions. Mixing business logic inside Flutter Widgets leads to tight coupling, rebuild overhead, and untestable code.

## Decision

We adopt **`flutter_bloc`** as the standard state management library across all mobile features. UI screens must adhere to the `Events -> Bloc -> States` unidirectional flow. All screen widgets must be `StatelessWidget`, with UI rendering governed strictly by `BlocBuilder` and `BlocConsumer`.

## Options Considered

1. **`setState` / InheritedWidget** — Suitable only for localized ephemerality (e.g., toggling a password visibility icon), but impossible to maintain for global auth states, complex place filtering, or multi-step itinerary creation.
2. **Provider / ChangeNotifier** — Easy to learn, but mutable states can cause unexpected side-effects and lack strict event-driven debugging traceability.
3. **Riverpod** — Strong compile-time safety and dependency injection, but has higher abstraction churn across major versions and steeper team learning curve.
4. **`flutter_bloc`** — Strict separation between UI and business logic, explicit immutable states, deterministic event pipelines, and excellent testability. ✅

## Consequences

- **Positive:**
  - 100% testable business logic without rendering Flutter widgets.
  - Predictable 4-state UI lifecycle for every screen: `Initial`, `Loading`, `Success`, `Error`.
  - Seamless integration with Flutter DevTools for event timeline inspection.
- **Negative:**
  - Requires writing boilerplate for Events and States for every feature (mitigated by using Bloc extensions and code generation templates).
