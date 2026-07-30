# Architecture

## Status

Planned. This document describes boundaries only; no application component is
implemented in the current scaffold.

## System shape

- Flutter and Dart own Android UI and business orchestration.
- Kotlin owns foreground location, notifications, permissions, and durable
  native location logging.
- MethodChannel and EventChannel connect Flutter to native Android code.
- Drift and SQLite store local trips, tracks, photos, and cached spots.
- Room and SQLite buffer native location points before Flutter synchronization.
- A stateless Go API owns accounts, shooting spots, and favorites.
- PostgreSQL stores server business data; Redis supports verification codes.
- OpenAPI defines the mobile/API boundary.

## Principles

1. Store full tracks and original photos locally by default.
2. Request location only after an explicit user action.
3. Keep map-provider code behind a replaceable adapter.
4. Record and convert coordinate systems explicitly.
5. Keep API services stateless and secrets outside source control.

## Planned repository boundaries

```text
apps/mobile        Flutter Android client and Kotlin bridge
services/api       Go HTTP API
packages/api_client Shared or generated OpenAPI client
docs               Product and engineering decisions
infra              Local and deployment infrastructure
```
