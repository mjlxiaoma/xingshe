# Privacy, permissions, and deletion

## Data ownership

| Data | Location | Uploaded by MVP |
| --- | --- | --- |
| Account, profile, favorites, Token hashes | PostgreSQL | Required for account features |
| Rate limits and failed-login counters | Redis with TTL | Required for API protection |
| Access/refresh Token and device ID | Android secure storage | Sent only to authentication endpoints |
| Trips, precise tracks, statistics | Device Drift/SQLite | No |
| Unsynchronized location points | Device Room/SQLite | No |
| Captured originals | Android MediaStore | No |
| Imported originals | User-selected document provider | No |
| Share PNG and thumbnails | App cache | No |

Android automatic backup is disabled. Uninstalling the app removes secure storage, Drift, Room and app cache, but does not automatically delete originals owned by MediaStore or another document provider.

## Permission policy

| Permission or consent | Request timing | Purpose |
| --- | --- | --- |
| AMap SDK privacy consent | Before the first map platform view | Map rendering and SDK processing disclosure |
| Foreground precise location | When entering a location-dependent flow | Current location and route points |
| Background location | Only when the user starts background trip recording | Continue a user-started trip while backgrounded |
| Foreground service/notification | When trip recording starts | Keep Android location recording visible and controllable |
| Camera | When the user chooses to take a photo | Launch the system camera |
| Photos/document access | When the user chooses to import | Select originals through the system picker |

Opening the app alone must not start location collection. Denying AMap consent prevents SDK initialization. Ending a trip stops the foreground location service. Permission denial keeps a retry or system-settings path and must not silently broaden access.

## Local deletion

- Deleting a completed trip removes that Drift trip and cascades to its track points, statistics and photo associations.
- Trip deletion never deletes system originals.
- Removing one photo from a trip deletes only its database association by default.
- A camera-created MediaStore original can be deleted only through a separate explicit confirmation.
- An imported original cannot be deleted by the app; the user manages it in the owning system provider.
- App cache files such as share PNGs may be cleared by Android at any time.

## Account deletion policy

Account deletion is a release gate. The approved behavior is:

1. Require an authenticated, explicit second confirmation.
2. Delete the server account and cascade server-side favorites, refresh Tokens, verification-code records and other account-owned data.
3. Clear the current device session after server success.
4. Preserve local trips by default because they are device-owned and may predate the account.
5. Offer a separate option to clear local trips; even then, system photo originals remain and require separate user action.
6. Provide an external request route that does not require an active login through the public `PRIVACY_CONTACT_EMAIL` contact.

The privacy page and the signed-out login flow link to an external account-deletion guide. The app displays the public contact injected through `PRIVACY_CONTACT_EMAIL` without storing a real address in source or the Pencil prototype. External requests require identity verification before deletion and must not ask users to send passwords, verification codes or Tokens.

## Sharing and logs

Share images omit account identity, email, Token and precise addresses. Route thumbnails use normalized relative coordinates rather than exact latitude/longitude. Images are generated locally and passed to other apps only after the user opens the Android share panel.

Logs use an allowlist. Client reports contain only an internal event, sanitized API error code and optional HTTP status. Server request logs contain request ID, method, path, status and duration; they omit Authorization, Query, body, verification codes, emails, exact coordinates and panic values. No third-party monitoring key is configured.
