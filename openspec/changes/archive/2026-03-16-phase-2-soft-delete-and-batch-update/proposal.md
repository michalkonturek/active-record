## Why

Production apps commonly need soft delete (marking records as deleted without removing them) and bulk mutation (updating many records in one call). Neither is provided by SwiftData, and both are high-frequency patterns that every app ends up reimplementing. Adding them continues the library's goal of bringing Rails-like ActiveRecord conveniences to SwiftData.

## What Changes

- **New `SoftDeletable` protocol:** A protocol extending `Queryable` that adds a `deletedAt: Date?` property, `softDelete()` and `restore()` instance methods, and automatic exclusion of soft-deleted records from all standard `Queryable` queries. Provides `withTrashed` and `onlyTrashed` escape hatches for accessing soft-deleted records.
- **New `updateAll` method on `Queryable`:** A static method `updateAll(where:in:apply:)` that fetches matching records and applies a mutation closure to each. Ergonomic sugar over the manual fetch-loop pattern.
- **Spike required for SoftDeletable:** Must verify that `#Predicate { $0.deletedAt == nil }` compiles in a protocol extension where `Self: SoftDeletable`. If not, a workaround is needed (e.g., post-fetch filtering or conformer-provided predicate).

## Capabilities

### New Capabilities

- `soft-delete`: SoftDeletable protocol with softDelete(), restore(), auto-exclusion from queries, withTrashed/onlyTrashed escape hatches.
- `batch-update`: updateAll(where:in:apply:) method for bulk mutations on Queryable models.

### Modified Capabilities

- `queryable`: Adding updateAll method to the Queryable protocol extension.

## Impact

- **Source files:** New `SoftDeletable.swift` in `Sources/active-record/`. Addition to `Queryable.swift` for `updateAll`.
- **Test files:** New test suites for soft delete and batch update in `Tests/active-record-tests/`.
- **Test models:** Need a `SoftDeletable`-conforming test model with `deletedAt` property.
- **Public API:** Additive only — no breaking changes.
- **Dependencies:** None.
