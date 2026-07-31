# XingShe

XingShe is a local-first Android tool for planning and recording photography trips.
The repository contains a Flutter Android app, a Go API, and a Docker Compose
development stack with PostgreSQL and Redis.

## Repository layout

- `apps/mobile/`: Flutter Android client
- `services/api/`: Go API service
- `packages/api_client/`: generated or shared API client
- `docs/`: architecture, API, product, ADR, and operations documents
- `infra/`: local and deployment infrastructure configuration

## Local setup

```sh
git clone https://github.com/mjlxiaoma/xingshe.git
cd xingshe
```

Copy `.env.example` to `.env`, then start and verify the local services:

```sh
docker compose up -d --build
curl http://127.0.0.1:8080/healthz
```

See [docs/operations/local-development.md](docs/operations/local-development.md)
for tool installation, Android, validation, shutdown, and troubleshooting steps.

## Product boundaries

- Android only for the MVP
- Local-first trip, track, and photo data
- No upload of raw photos or complete user tracks
- Replaceable map provider behind an adapter
- OpenAPI is the client/server contract

See [docs/architecture.md](docs/architecture.md) for the planned system shape.
