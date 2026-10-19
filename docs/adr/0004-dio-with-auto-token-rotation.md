# 0004. Dio Interceptors for JWT Refresh Token Rotation

- Date: 2026-10-17
- Status: accepted
- Deciders: Engineer A (Backend), Engineer B (Mobile)

## Context

Mobile users expect long-lived authentication sessions without being repeatedly forced to log in. However, long-lived Access Tokens pose severe security hazards if leaked. 

To satisfy enterprise security guidelines, Access Tokens must be short-lived (30 minutes), while Refresh Tokens are valid for 7 days. The mobile network client must transparently intercept HTTP `401 Unauthorized` responses, exchange the refresh token for a new token pair, and seamlessly replay the failed request without interrupting the user.

## Decision

We use the **`dio`** HTTP package configured with a custom `AuthInterceptor`. Tokens are persisted securely using `flutter_secure_storage` (Android Keystore / iOS Keychain). 

When a request encounters a `401 Unauthorized`, the interceptor locks the request queue, invokes the `POST /api/v1/auth/refresh-token` endpoint, rotates both Access and Refresh tokens, and retries the original request with the fresh token.

## Options Considered

1. **Standard `http` package with manual error handling** — Requires wrapping every single API repository call with try-catch logic to detect 401 and trigger refresh, resulting in massive code duplication and race conditions when multiple concurrent requests expire simultaneously.
2. **Dio with QueuedInterceptor / Custom Lock** — Centralized request and response pipeline, built-in retry mechanics, connection timeout safeguards, and global header injection. ✅

## Consequences

- **Positive:**
  - Zero disruption to user experience when short-lived Access Tokens expire.
  - Full adherence to Refresh Token Rotation security standards.
  - Single point of maintenance for logging, base URLs, and authentication headers.
- **Negative:**
  - Concurrency locks must be carefully tested to prevent deadlocks when multiple parallel requests trigger token refresh simultaneously.
