## 1. Validatable Protocol & Error Type

- [x] 1.1 Create `Validatable.swift` with protocol definition extending `PersistentModel`, requiring `func validate() throws`
- [x] 1.2 Define `ValidationError` struct with `failures: [FieldError]`, conforming to `Error` and `LocalizedError`
- [x] 1.3 Define `ValidationError.FieldError` with `field: String` and `message: String`
- [x] 1.4 Add convenience initializer `ValidationError(field:message:)` for single-field errors
- [x] 1.5 Implement `isValid` computed property via protocol extension

## 2. Auto-Validation Integration

- [x] 2.1 Add auto-validate to `Upsertable.createOrUpdate(from:using:in:)` — validate after insert, remove from context if invalid
- [x] 2.2 Add auto-validate to `Queryable.firstOrCreate(where:in:create:)` — validate before insert on create path only

## 3. Test Model

- [x] 3.1 Create `Validatable`-conforming test model (e.g., `Item` with name length and price range validations)

## 4. Validation Tests

- [x] 4.1 Write tests for `validate()`: valid model does not throw, invalid model throws `ValidationError`
- [x] 4.2 Write tests for `ValidationError`: single failure, multiple failures, errorDescription content
- [x] 4.3 Write tests for `isValid`: returns true for valid, false for invalid
- [x] 4.4 Write tests for auto-validate in `createOrUpdate`: valid passes, invalid throws and model removed from context
- [x] 4.5 Write tests for auto-validate in `firstOrCreate`: valid passes, invalid throws and model not inserted, existing model not validated
- [x] 4.6 Verify non-Validatable models are unaffected (existing tests still pass)

## 5. Final Verification

- [x] 5.1 Run full test suite — `swift test` — all tests pass
- [x] 5.2 Run `swift build` — no warnings or errors
- [x] 5.3 Run `xcrun swift-format lint --strict --recursive Sources/ Tests/ Package.swift Demo/` — no errors
