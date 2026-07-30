# ADR 0002: Map provider abstraction

- Status: Proposed

Business and presentation code depend on a map adapter rather than a vendor
SDK. Provider-specific coordinate conversion and SDK integration stay behind
that boundary.
