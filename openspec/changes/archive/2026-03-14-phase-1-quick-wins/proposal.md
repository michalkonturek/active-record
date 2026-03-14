## Why

The library covers core CRUD and JSON upsert well, but common Active Record conveniences are missing: numeric aggregates (sum, average), field extraction (pluck), find-or-create patterns, and timestamp management. These are high-frequency operations that every app using the library ends up reimplementing. Shipping them together as a single release rounds out the query API and adds two new protocols that follow the library's existing zero-boilerplate pattern.

## What Changes

- **New aggregate methods on Queryable:** `sum(for:)`, `average(for:)`, and `pluck(_:)` with optional predicate filtering, extending the existing `withMaxValue` / `withMinValue` pattern.
- **New find-or-create methods on Queryable:** `firstOrCreate(where:in:create:)` and `firstOrInitialize(where:in:create:)` using a type-safe closure for the create path. Neither auto-saves, consistent with existing conventions.
- **New `Timestampable` protocol:** Requires `createdAt` and `updatedAt` properties, provides `touch()` and `stampCreated()` helpers. Auto-stamps in `createOrUpdate()` and `firstOrCreate()` when the model conforms.

## Capabilities

### New Capabilities

- `aggregates`: Sum, average, and pluck query methods on Queryable — numeric aggregation and single-field extraction.
- `find-or-create`: firstOrCreate and firstOrInitialize convenience finders that create records when no match exists.
- `timestampable`: Timestampable protocol for managed createdAt/updatedAt timestamps with touch() and stampCreated() helpers.

### Modified Capabilities

- `queryable`: Adding aggregate methods (sum, average, pluck) and find-or-create methods to the Queryable protocol extension.
- `upsertable`: Auto-stamping timestamps in createOrUpdate() when model conforms to Timestampable.

## Impact

- **Source files:** New `Timestampable.swift` in `Sources/active-record/`. Extensions to `Queryable.swift` for aggregates and find-or-create. Small addition to `Upsertable.swift` for timestamp auto-stamping.
- **Test files:** New tests for each capability in `Tests/active-record-tests/`.
- **Test models:** May need a `Timestampable`-conforming test model.
- **Public API:** Additive only — no breaking changes. Existing code compiles unchanged.
- **Dependencies:** None — all implementations use SwiftData and Swift standard library only.
