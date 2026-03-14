## ADDED Requirements

### Requirement: Aggregate query methods

The `Queryable` protocol extension SHALL provide `sum(for:where:in:)`, `average(for:where:in:)`, and `pluck(_:where:in:)` static methods. These methods SHALL follow the existing pattern of explicit `ModelContext` parameter and optional `Predicate<Self>` filtering. See `specs/aggregates/spec.md` for detailed requirements.

#### Scenario: Aggregate methods available on Queryable conformers
- **WHEN** a model conforms to `Queryable`
- **THEN** it SHALL have access to `sum`, `average`, and `pluck` methods with no additional conformance required

### Requirement: Find-or-create convenience methods

The `Queryable` protocol extension SHALL provide `firstOrCreate(where:in:create:)` and `firstOrInitialize(where:in:create:)` static methods. See `specs/find-or-create/spec.md` for detailed requirements.

#### Scenario: Find-or-create methods available on Queryable conformers
- **WHEN** a model conforms to `Queryable`
- **THEN** it SHALL have access to `firstOrCreate` and `firstOrInitialize` methods with no additional conformance required
