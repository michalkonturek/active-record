# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-03-16

### Added

- **SoftDeletable protocol:** New `SoftDeletable` protocol extending `Queryable` with `deletedAt: Date?`. Provides `softDelete()` and `restore()` instance methods. Standard queries (`all`, `first`, `count`, `exists`, `deleteAll`) auto-exclude soft-deleted records. Escape hatches: `allWithTrashed`, `allOnlyTrashed`, `countWithTrashed`, `countOnlyTrashed`, `existsWithTrashed`. `deleteAll` soft-deletes by default; `destroyAll` for permanent deletion.
- **Batch update:** `updateAll(where:in:apply:)` on `Queryable` for bulk mutations via closure.

## [1.1.0] - 2026-03-14

### Added

- **Aggregates:** `sum(for:where:in:)`, `average(for:where:in:)`, and `pluck(_:where:in:)` methods on `Queryable`. Sum uses `AdditiveArithmetic`, average returns `Double?` (nil for empty sets), pluck extracts a single field as `[V]`.
- **Find or Create:** `firstOrCreate(where:in:create:)` and `firstOrInitialize(where:in:create:)` on `Queryable`. Uses a type-safe closure for the create path. `firstOrCreate` inserts into context; `firstOrInitialize` does not. Neither auto-saves.
- **Timestampable protocol:** New `Timestampable` protocol requiring `createdAt` and `updatedAt` properties. Provides `touch()` (sets `updatedAt`) and `stampCreated()` (sets both) helpers via protocol extension.
- **Auto-stamping:** `createOrUpdate()` and `firstOrCreate()` automatically call `stampCreated()` on models conforming to `Timestampable`.

## [1.0.0] - 2025-05-01

### Added

- Initial release.
- `Queryable` protocol with `all`, `first`, `count`, `exists`, `withMaxValue`, `withMinValue`, `deleteAll` methods.
- `Upsertable` protocol with `createOrUpdate` from JSON `Data`, dictionaries, and batch arrays.
