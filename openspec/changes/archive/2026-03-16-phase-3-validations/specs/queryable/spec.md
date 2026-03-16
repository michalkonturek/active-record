## ADDED Requirements

### Requirement: Auto-validate in firstOrCreate when model is Validatable

When a model conforms to both `Queryable` and `Validatable`, the `firstOrCreate(where:in:create:)` method SHALL call `validate()` on newly created models before insertion. If validation fails, `ValidationError` SHALL be thrown and the model SHALL NOT be inserted. Existing matched models SHALL NOT be validated.

#### Scenario: firstOrCreate validates new Validatable model
- **WHEN** `firstOrCreate` creates a new invalid `Validatable` model
- **THEN** `ValidationError` SHALL be thrown and model not inserted

#### Scenario: firstOrCreate does not validate existing model
- **WHEN** `firstOrCreate` returns an existing `Validatable` model
- **THEN** `validate()` SHALL NOT be called
