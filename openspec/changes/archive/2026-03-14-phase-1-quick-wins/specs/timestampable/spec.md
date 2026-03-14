## ADDED Requirements

### Requirement: Timestampable protocol definition

The system SHALL define a `Timestampable` protocol constrained to `PersistentModel` requiring two mutable stored properties: `createdAt: Date` and `updatedAt: Date`. Conformance SHALL require models to declare these properties explicitly in their `@Model` class.

#### Scenario: Model conforms to Timestampable
- **WHEN** a `@Model` class declares `var createdAt: Date` and `var updatedAt: Date` and conforms to `Timestampable`
- **THEN** it SHALL compile and gain access to `touch()` and `stampCreated()` methods

### Requirement: touch() sets updatedAt to current date

The system SHALL provide a `touch()` instance method via protocol extension that sets `updatedAt` to `Date()` (current date/time). The method SHALL NOT modify `createdAt`.

#### Scenario: Calling touch on existing record
- **WHEN** `record.touch()` is called on a `Timestampable` model
- **THEN** `updatedAt` SHALL be set to the current date and `createdAt` SHALL remain unchanged

### Requirement: stampCreated() sets both timestamps

The system SHALL provide a `stampCreated()` instance method via protocol extension that sets both `createdAt` and `updatedAt` to `Date()` (current date/time).

#### Scenario: Calling stampCreated on new record
- **WHEN** `record.stampCreated()` is called on a new `Timestampable` model
- **THEN** both `createdAt` and `updatedAt` SHALL be set to the same current date

### Requirement: Auto-stamp in createOrUpdate when model is Timestampable

When a model conforms to both `Upsertable` and `Timestampable`, the `createOrUpdate(from:in:)` method SHALL automatically call `stampCreated()` on the decoded model after insertion. This SHALL apply to both single and batch upsert methods.

#### Scenario: Upsert auto-stamps timestamps
- **WHEN** `createOrUpdate(from:in:)` is called on a model conforming to both `Upsertable` and `Timestampable`
- **THEN** the returned model SHALL have `createdAt` and `updatedAt` set to the current date

### Requirement: Auto-stamp in firstOrCreate when model is Timestampable

When a model conforms to both `Queryable` and `Timestampable`, the `firstOrCreate(where:in:create:)` method SHALL automatically call `stampCreated()` on newly created models (but NOT on existing matched models).

#### Scenario: firstOrCreate creates new record — auto-stamps
- **WHEN** `firstOrCreate` creates a new `Timestampable` model (no match found)
- **THEN** `stampCreated()` SHALL be called on the new model

#### Scenario: firstOrCreate finds existing record — no stamping
- **WHEN** `firstOrCreate` returns an existing `Timestampable` model (match found)
- **THEN** timestamps SHALL NOT be modified
