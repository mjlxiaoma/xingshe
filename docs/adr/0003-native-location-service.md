# ADR 0003: Native Android location service

- Status: Accepted

Kotlin owns foreground location recording and persists points through Room.
Flutter controls the trip workflow and imports buffered points into Drift.

Each native row uses a UUID `nativeLogId`, a trip ID, WGS-84 coordinates,
accuracy, speed, timestamp, and synchronization state. Drift enforces unique
`nativeLogId` values so retries are idempotent. Room is a short-term buffer,
not a second trip database; synchronized rows are removed or marked for cleanup.
Ending a trip stops the foreground service.
