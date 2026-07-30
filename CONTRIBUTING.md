# Contributing

## Branches

- `main`: stable code
- `develop`: integration work
- `feature/<task-id>-<name>`: feature work
- `fix/<issue>-<name>`: fixes

## Commits

Use `<type>(<scope>): <summary>`, for example:

```text
feat(auth): implement email verification login API
```

Keep each commit limited to one task. Before committing, inspect the diff and
run the checks relevant to the changed component.

Never commit credentials, `.env` files, Android keystores, map keys, private
user coordinates, or user photos.
