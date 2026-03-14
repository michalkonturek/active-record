# Find or Create — Convenience Finders

## Purpose

Provide `firstOrCreate` and `firstOrInitialize` convenience methods on `Queryable` that find an existing record or create a new one using a type-safe closure.

## Specification

### Find existing or create new record

The system SHALL provide a static method `firstOrCreate(where:in:create:)` on `Queryable` that returns the first record matching the predicate, or creates and inserts a new one using the provided closure if no match exists. The method SHALL be marked `@discardableResult`. The create closure SHALL only be called when no match is found. The new record SHALL be inserted into the context via `context.insert()`. The method SHALL NOT auto-save the context.

### Find existing or initialize without persisting

The system SHALL provide a static method `firstOrInitialize(where:in:create:)` on `Queryable` that returns the first record matching the predicate, or creates a new one using the provided closure WITHOUT inserting it into the context. The create closure SHALL only be called when no match is found.

## Verification

- Unit tests SHALL verify firstOrCreate returns existing record when match found.
- Unit tests SHALL verify firstOrCreate creates and inserts when no match found.
- Unit tests SHALL verify firstOrCreate does NOT auto-save.
- Unit tests SHALL verify firstOrInitialize returns existing record when match found.
- Unit tests SHALL verify firstOrInitialize creates but does NOT insert when no match found.
- Tests SHALL use an in-memory `ModelContainer` for isolation.
