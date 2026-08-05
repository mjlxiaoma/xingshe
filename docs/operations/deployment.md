# Deployment and operations

## Current status

Production deployment is outside the MVP and is intentionally not configured or executed. The repository has no production domain, HTTPS termination, managed database, object storage, formal Release signing or store submission configuration.

The repository includes authenticated account deletion and a signed-out external request guide. Before any release, configure and publish the real privacy contact, complete Android real-device acceptance and a formal security review, and prepare production secrets, Release signing and store privacy disclosures.

## Recommended production shape

- Build the API image from `services/api/Dockerfile` and promote an immutable digest between environments.
- Run at least two stateless API instances behind HTTPS termination and health checks.
- Use managed PostgreSQL with encrypted storage, private networking and restricted credentials.
- Use Redis only for expiring limits and counters; loss of Redis must not lose persistent business data.
- Inject `DATABASE_URL`, `REDIS_ADDR`, `JWT_SECRET` and SMTP credentials from a secret manager at runtime. Do not bake `.env` into an image.
- Keep SMTP on implicit TLS 465 and restrict the sender account to application mail.
- Do not add an object store until a user-facing cloud media feature exists; precise tracks and originals remain out of scope.

## Release sequence

1. Build and scan the API image and signed Android artifact in CI.
2. Back up PostgreSQL and verify the backup metadata before migration.
3. Run `xingshe-migrate up` as a controlled one-off job with the same image version.
4. Deploy the API, wait for `/healthz`, then enable traffic gradually.
5. Run authentication, profile, spot and favorite smoke tests without using production user data.
6. Monitor error rate, latency, database connections, Redis availability and SMTP delivery failures.

Migrations must not run automatically in every API replica. Rollback should first restore the previous API image. Run `xingshe-migrate down` only when the migration explicitly supports lossless rollback and a current backup exists.

## PostgreSQL backup

- Take encrypted daily logical backups and retain them in a separate account or failure domain.
- Enable continuous WAL archiving and point-in-time recovery when the recovery objective requires it.
- Record backup time, database version, migration version, checksum and retention expiry.
- Restrict backup access and audit restore/download operations.
- Test restoration into an isolated database on a schedule; a backup is not accepted until a restore and application smoke test pass.
- Define recovery point and recovery time objectives before launch, then size retention and drills to those objectives.

A typical controlled logical backup uses `pg_dump --format=custom --no-owner`. Restore testing uses `pg_restore` against a new isolated database, never the live database. Connection values must come from the secret manager and must not appear in shell history or logs.

## Redis and cleanup jobs

Redis is rebuildable and is not included in the business-data recovery plan. All rate-limit and login-attempt keys require TTL. A scheduled database job should remove expired verification-code rows and expired or revoked refresh Tokens; monitor job failures and table growth.

## Device data

The server cannot back up or restore local trips, tracks or photo associations because they are never uploaded. Android automatic backup is disabled. Until an explicit encrypted export feature exists, users must treat local trip data as a single-device copy. System photo originals follow the user's Android gallery and cloud-backup settings, not the app database lifecycle.

## Operational privacy

- Keep request logging on the existing allowlist and never enable body/Header dumps in production.
- Restrict database access to the API and controlled migration/backup jobs.
- Rotate JWT and SMTP secrets through a documented process; JWT rotation signs out existing sessions unless overlapping verification is implemented.
- Publish the privacy contact and external deletion process before release.
- Inject `PRIVACY_CONTACT_EMAIL` into the Android build with `--dart-define`; do not hardcode the real address in source or build scripts.
- External deletion requests must be accepted without an active login, verified against account ownership, and processed through the same server-side deletion boundary as in-app requests.
- Maintain incident procedures for credential exposure, unauthorized access, backup compromise and accidental deletion.
