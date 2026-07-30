# XingShe

XingShe is a local-first Android tool for planning and recording photography trips.
The repository is currently an architecture-only scaffold: no mobile app, API,
database, or container service has been initialized yet.

## Repository layout

- `apps/mobile/`: planned Flutter Android client
- `services/api/`: planned Go API service
- `packages/api_client/`: planned generated or shared API client
- `docs/`: architecture, API, product, ADR, and operations documents
- `infra/`: planned local and deployment infrastructure configuration

## Local setup

```sh
git clone https://github.com/mjlxiaoma/xingshe.git
cd xingshe
```

Flutter, Go, PostgreSQL, and Redis setup commands will be added when their
projects are initialized. There is intentionally no runnable application in
this scaffold. If GNU Make is available, `make help` prints the same status.

## Product boundaries

- Android only for the MVP
- Local-first trip, track, and photo data
- No upload of raw photos or complete user tracks
- Replaceable map provider behind an adapter
- OpenAPI is the client/server contract

See [docs/architecture.md](docs/architecture.md) for the planned system shape.
