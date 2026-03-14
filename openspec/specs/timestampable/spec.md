# Timestampable — Managed Timestamps Protocol

## Purpose

Provide a `Timestampable` protocol for managed `createdAt` / `updatedAt` timestamps with helper methods and auto-stamping integration with `Upsertable` and `Queryable`.

## Specification

### Protocol Definition

The system SHALL define a `Timestampable` protocol constrained to `PersistentModel` requiring two mutable stored properties: `createdAt: Date` and `updatedAt: Date`. Conformance SHALL require models to declare these properties explicitly in their `@Model` class.

### touch()

The system SHALL provide a `touch()` instance method via protocol extension that sets `updatedAt` to `Date()` (current date/time). The method SHALL NOT modify `createdAt`.

### stampCreated()

The system SHALL provide a `stampCreated()` instance method via protocol extension that sets both `createdAt` and `updatedAt` to `Date()` (current date/time).

### Auto-stamp in createOrUpdate

When a model conforms to both `Upsertable` and `Timestampable`, the `createOrUpdate(from:in:)` method SHALL automatically call `stampCreated()` on the decoded model after insertion. This SHALL apply to both single and batch upsert methods.

### Auto-stamp in firstOrCreate

When a model conforms to both `Queryable` and `Timestampable`, the `firstOrCreate(where:in:create:)` method SHALL automatically call `stampCreated()` on newly created models (but NOT on existing matched models).

## Design Constraints

- Auto-stamping is best-effort: only library methods (`createOrUpdate`, `firstOrCreate`) auto-stamp. Direct `context.insert()` calls require manual `stampCreated()`.
- SwiftData has no per-model lifecycle hooks, so fully automatic timestamps are not possible.

## Verification

- Unit tests SHALL verify `touch()` updates only `updatedAt`.
- Unit tests SHALL verify `stampCreated()` sets both timestamps to the same date.
- Unit tests SHALL verify auto-stamp in `createOrUpdate` sets timestamps.
- Unit tests SHALL verify auto-stamp in `firstOrCreate` sets timestamps on new models only.
- Unit tests SHALL verify non-Timestampable models are unaffected.
- Tests SHALL use an in-memory `ModelContainer` for isolation.
