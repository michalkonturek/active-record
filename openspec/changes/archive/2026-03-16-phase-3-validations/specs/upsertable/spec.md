## ADDED Requirements

### Requirement: Auto-validate in createOrUpdate when model is Validatable

When a model conforms to both `Upsertable` and `Validatable`, the `createOrUpdate(from:in:)` and `createOrUpdate(fromArray:in:)` methods SHALL call `validate()` after insertion. If validation fails, the model SHALL be removed from the context and the error re-thrown. Non-Validatable models SHALL be unaffected.

#### Scenario: Upsertable + Validatable model is validated
- **WHEN** `createOrUpdate(from:in:)` inserts an invalid `Validatable` model
- **THEN** `ValidationError` SHALL be thrown and the model removed from context

#### Scenario: Upsertable-only model is unaffected
- **WHEN** `createOrUpdate(from:in:)` is called on a non-Validatable model
- **THEN** behavior SHALL be unchanged
