# Deployment

Production deployment is outside the MVP and is intentionally not configured.
Before release, inject secrets outside the image, terminate HTTPS, run
`xingshe-migrate up` as a controlled deployment step, and keep rollback and
privacy-safe logging procedures.

## Data operations

- Back up PostgreSQL daily, retain encrypted backups separately, and enable WAL archiving/PITR according to the required recovery window. Test restoration regularly before relying on it.
- Treat Redis as rebuildable cache and temporary state, never as the only copy of business data. All rate-limit and login-failure keys require TTL.
- Delete expired `email_verification_codes` and expired/revoked `refresh_tokens` with a scheduled database job; monitor row counts and job failures.
- Do not upload precise tracks or original trip photos. Add OSS/S3/COS and CDN only when public spot covers, avatars, or explicit optional cloud sync are implemented; PostgreSQL stores object URLs, not file bytes.
- Account deletion is a release blocker: after Pencil confirmation, implement in-app deletion, token revocation, server-side cascade cleanup, and an external deletion entry.
