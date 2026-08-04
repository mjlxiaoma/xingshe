# ADR 0002: Map provider abstraction

- Status: Accepted

Business and presentation code depend on a map adapter rather than a vendor
SDK. Provider-specific coordinate conversion and SDK integration stay behind
that boundary.

The Android adapter uses a Dart 3-compatible maintenance of AMap's Flutter
plugin backed by the official AMap Android SDK. The application persists
explicit consent before creating the platform map view, and the view passes the
AMap privacy statement so Android calls `updatePrivacyShow` before
`updatePrivacyAgree`. The Android key is injected through a manifest placeholder
and is never committed or sent in platform-view creation parameters.
