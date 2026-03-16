## Why

Swift's type system prevents many errors at compile time, but runtime constraints — string length, numeric ranges, email format, cross-field consistency — still require manual checking. Every app writes ad-hoc validation logic scattered across view models and controllers. A minimal `Validatable` protocol gives models a standard place to declare their runtime constraints, making validation discoverable and testable.

The goal is intentionally minimal: just the protocol contract and a lightweight error type. No rules DSL, no declarative builder — users write plain Swift in `validate()`. If demand emerges, the community can build DSLs on top.

## What Changes

- **New `Validatable` protocol:** A protocol extending `PersistentModel` with a single required method `func validate() throws`. Models implement validation logic in plain Swift.
- **New `ValidationError` type:** A structured error type that collects per-field validation failures, providing field name, message, and the ability to aggregate multiple errors.
- **Integration with `Upsertable`:** `createOrUpdate()` optionally validates models conforming to both `Upsertable` and `Validatable` before insertion.
- **Integration with `Queryable`:** `firstOrCreate()` optionally validates on the create path when the model conforms to `Validatable`.

## Capabilities

### New Capabilities

- `validatable`: Validatable protocol with validate() method, ValidationError type, and integration with existing create/upsert flows.

### Modified Capabilities

- `upsertable`: Auto-validate in createOrUpdate() when model conforms to Validatable.
- `queryable`: Auto-validate in firstOrCreate() on the create path when model conforms to Validatable.

## Impact

- **Source files:** New `Validatable.swift` in `Sources/ActiveRecord/`. Small additions to `Upsertable.swift` and `Queryable.swift` for auto-validation.
- **Error types:** New `ValidationError` added to `Errors.swift` or in `Validatable.swift`.
- **Test files:** New test suite for validation in `Tests/active-record-tests/`.
- **Test models:** Need a `Validatable`-conforming test model with validation rules.
- **Public API:** Additive only — no breaking changes.
- **Dependencies:** None.
