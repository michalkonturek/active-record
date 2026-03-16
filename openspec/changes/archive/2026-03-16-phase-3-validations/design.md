## Context

The library provides `Queryable`, `Upsertable`, `Timestampable`, and `SoftDeletable` protocols on SwiftData's `PersistentModel`. All protocols follow a pattern: extend `PersistentModel`, provide default implementations via protocol extensions, require explicit `ModelContext`. The roadmap specifies a minimal validation approach — protocol contract only, no rules DSL.

## Goals / Non-Goals

**Goals:**

- Define a `Validatable` protocol with a single `validate() throws` method
- Provide a `ValidationError` type that supports per-field error messages and multiple failures
- Auto-validate in `createOrUpdate()` and `firstOrCreate()` when models conform to `Validatable`
- Provide an `isValid` convenience property
- Keep the API minimal enough that users write plain Swift — no framework to learn

**Non-Goals:**

- Declarative validation rules DSL (e.g., `validates(\.email, .format(...))`)
- Async validation (e.g., uniqueness checks that query the database)
- Automatic validation on every property mutation
- UI-layer error binding or localization framework

## Decisions

### 1. Validatable requires PersistentModel, not Queryable

**Decision:** `Validatable` extends `PersistentModel` directly, not `Queryable`.

**Rationale:** Validation is independent of querying. A model might need validation without conforming to `Queryable`. Keeping the constraint minimal follows the pattern of `Timestampable` which also extends `PersistentModel` directly.

### 2. validate() throws rather than returning [ValidationError]

**Decision:** `validate()` throws a `ValidationError`. The error type supports multiple field failures.

**Rationale:** Throwing is idiomatic Swift for "this might fail." It integrates naturally with `try` in `createOrUpdate()` and `firstOrCreate()`. A `ValidationError` can hold multiple field errors, so callers can inspect all failures at once.

**Alternative considered:** `validate() -> [ValidationError]` returning an array. Rejected — requires callers to check the array manually. The throwing pattern is more ergonomic and consistent with the library's existing `throws` convention.

### 3. ValidationError supports multiple field failures

**Decision:** `ValidationError` contains an array of `FieldError(field: String, message: String)` and conforms to `Error` and `LocalizedError`.

```swift
public struct ValidationError: Error, LocalizedError {
    public let failures: [FieldError]

    public struct FieldError: Sendable {
        public let field: String
        public let message: String
    }
}
```

**Rationale:** Real-world validation often produces multiple errors (e.g., both name and email are invalid). A flat list of field/message pairs is the simplest structure that's still useful. No nesting, no error codes — just strings.

### 4. Convenience isValid property via protocol extension

**Decision:** Provide `var isValid: Bool` as a default implementation that calls `validate()` in a do/catch.

**Rationale:** Quick boolean check without needing try/catch. Useful for UI bindings and conditional logic. Follows Rails `valid?` pattern.

### 5. Auto-validation in createOrUpdate and firstOrCreate

**Decision:** When a model conforms to both `Upsertable` and `Validatable`, `createOrUpdate()` calls `validate()` on the decoded model after insertion. When `firstOrCreate()` creates a new record and the model conforms to `Validatable`, it validates before insertion.

**Rationale:** Consistent with auto-stamping for `Timestampable`. Validation at the persistence boundary catches errors early. The validation runs after decoding (for upsert) so all fields are populated.

**Important:** For `createOrUpdate`, validation runs after `context.insert()` because SwiftData may need the model in a context for property access. If validation fails, the model is deleted from the context before the error is thrown.

For `firstOrCreate`, validation runs before `context.insert()` since the model is created by user code and doesn't need context for property access.

### 6. ValidationError lives in Validatable.swift, not Errors.swift

**Decision:** Keep `ValidationError` in `Validatable.swift` alongside the protocol.

**Rationale:** `Errors.swift` contains `ActiveRecordError` which is specific to upsert operations. `ValidationError` is conceptually part of the validation feature. Co-locating them keeps the feature self-contained.

### 7. No helper methods for common validations

**Decision:** Don't provide `validatePresence`, `validateLength`, `validateFormat`, etc. Users write plain Swift.

**Rationale:** The roadmap explicitly says "no rules DSL." Helper methods are the first step toward a DSL. Plain Swift is more flexible, more discoverable (no API to learn), and can be extended by the community if needed.

## Risks / Trade-offs

**[Ergonomics] No validation helpers means more boilerplate** → Mitigation: Document common patterns in README examples (presence check, length check, format check). Users can extract their own helpers.

**[Order of operations] createOrUpdate validates after insert** → Mitigation: If validation fails, the inserted model is removed from context before throwing. Document this behavior clearly.

**[Scope] No async validation** → Mitigation: Document that uniqueness checks and other async validations should be performed separately before calling `validate()`. The protocol is synchronous by design.
