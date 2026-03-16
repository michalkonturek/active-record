## ADDED Requirements

### Requirement: Validatable protocol definition

The system SHALL define a `Validatable` protocol constrained to `PersistentModel` with a single required method `func validate() throws`. Models SHALL implement validation logic in the `validate()` method using plain Swift. The method SHALL throw a `ValidationError` when validation fails.

#### Scenario: Model conforms to Validatable
- **WHEN** a `@Model` class implements `func validate() throws` and conforms to `Validatable`
- **THEN** it SHALL compile and gain access to `isValid` property

### Requirement: ValidationError type

The system SHALL define a `ValidationError` struct conforming to `Error` and `LocalizedError`. It SHALL contain a `failures` array of `FieldError` values, each with a `field: String` and `message: String`. The `errorDescription` SHALL list all field failures.

#### Scenario: Single field failure
- **WHEN** a `ValidationError` is created with one `FieldError(field: "name", message: "can't be empty")`
- **THEN** `failures.count` SHALL be 1 and `errorDescription` SHALL include "name: can't be empty"

#### Scenario: Multiple field failures
- **WHEN** a `ValidationError` is created with multiple `FieldError` values
- **THEN** `failures` SHALL contain all errors and `errorDescription` SHALL list them all

### Requirement: Convenience initializer for single field

The system SHALL provide a convenience initializer `ValidationError(field:message:)` that creates a `ValidationError` with a single `FieldError`.

#### Scenario: Single-field convenience
- **WHEN** `ValidationError(field: "age", message: "must be positive")` is created
- **THEN** `failures` SHALL contain exactly one `FieldError` with the given field and message

### Requirement: isValid convenience property

The system SHALL provide a `var isValid: Bool` computed property via protocol extension that returns `true` when `validate()` does not throw and `false` when it throws.

#### Scenario: Valid model
- **WHEN** `isValid` is accessed on a model where `validate()` does not throw
- **THEN** the result SHALL be `true`

#### Scenario: Invalid model
- **WHEN** `isValid` is accessed on a model where `validate()` throws
- **THEN** the result SHALL be `false`

### Requirement: Auto-validate in createOrUpdate

When a model conforms to both `Upsertable` and `Validatable`, the `createOrUpdate(from:in:)` method SHALL call `validate()` on the decoded model after insertion into the context. If validation fails, the model SHALL be removed from the context and the `ValidationError` SHALL be thrown. This SHALL apply to both single and batch upsert methods.

#### Scenario: Valid model passes upsert
- **WHEN** `createOrUpdate(from:in:)` is called with valid data on a `Upsertable & Validatable` model
- **THEN** the model SHALL be inserted and returned normally

#### Scenario: Invalid model fails upsert
- **WHEN** `createOrUpdate(from:in:)` is called with data that produces an invalid model
- **THEN** `ValidationError` SHALL be thrown and the model SHALL NOT remain in the context

#### Scenario: Non-Validatable models are unaffected
- **WHEN** `createOrUpdate(from:in:)` is called on a model conforming only to `Upsertable`
- **THEN** behavior SHALL be identical to the current implementation (no validation)

### Requirement: Auto-validate in firstOrCreate

When a model conforms to both `Queryable` and `Validatable`, the `firstOrCreate(where:in:create:)` method SHALL call `validate()` on newly created models before insertion. If validation fails, the model SHALL NOT be inserted and `ValidationError` SHALL be thrown. Existing matched models SHALL NOT be validated.

#### Scenario: Valid new model passes firstOrCreate
- **WHEN** `firstOrCreate` creates a new valid `Validatable` model
- **THEN** the model SHALL be inserted and returned normally

#### Scenario: Invalid new model fails firstOrCreate
- **WHEN** `firstOrCreate` creates a new invalid `Validatable` model
- **THEN** `ValidationError` SHALL be thrown and the model SHALL NOT be in the context

#### Scenario: Existing model is not validated
- **WHEN** `firstOrCreate` returns an existing `Validatable` model
- **THEN** `validate()` SHALL NOT be called
