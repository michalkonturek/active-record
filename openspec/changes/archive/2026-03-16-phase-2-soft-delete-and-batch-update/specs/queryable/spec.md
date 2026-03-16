## ADDED Requirements

### Requirement: Batch update method

The `Queryable` protocol extension SHALL provide an `updateAll(where:in:apply:)` static method that fetches matching records and applies a mutation closure to each. See `specs/batch-update/spec.md` for detailed requirements.

#### Scenario: updateAll available on Queryable conformers
- **WHEN** a model conforms to `Queryable`
- **THEN** it SHALL have access to `updateAll` with no additional conformance required
