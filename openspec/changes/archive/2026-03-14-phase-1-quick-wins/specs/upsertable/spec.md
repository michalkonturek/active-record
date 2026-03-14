## ADDED Requirements

### Requirement: Auto-stamp timestamps in createOrUpdate

When a model conforms to both `Upsertable` and `Timestampable`, the `createOrUpdate(from:in:)` and `createOrUpdate(fromArray:in:)` methods SHALL call `stampCreated()` on each newly inserted model. This SHALL be implemented via a conditional conformance check (e.g., `if let model as? Timestampable`) after insertion.

#### Scenario: Upsertable + Timestampable model gets stamped
- **WHEN** `createOrUpdate(from:in:)` is called on a model that conforms to both `Upsertable` and `Timestampable`
- **THEN** the returned model SHALL have `createdAt` and `updatedAt` set

#### Scenario: Upsertable-only model is unaffected
- **WHEN** `createOrUpdate(from:in:)` is called on a model that conforms to `Upsertable` but NOT `Timestampable`
- **THEN** behavior SHALL be identical to the current implementation (no timestamp logic)
