## Context

The active-record library provides two protocols — `Queryable` (static finders) and `Upsertable` (JSON upsert) — as extensions on SwiftData's `PersistentModel`. All methods are static, take explicit `ModelContext`, and never auto-save. The library targets Swift 6.0 with strict concurrency.

SwiftData has no SQL-level aggregates, no partial projections, and no per-model lifecycle hooks. All aggregate and pluck operations must fetch full models and compute in-memory. Timestamps cannot be truly automatic — SwiftData provides no `willSave` callback on individual models.

## Goals / Non-Goals

**Goals:**

- Add `sum`, `average`, and `pluck` to `Queryable` following the same static method + explicit context pattern
- Add `firstOrCreate` and `firstOrInitialize` to `Queryable` with type-safe closure-based creation
- Introduce a `Timestampable` protocol with `touch()` and `stampCreated()` helpers
- Auto-stamp timestamps in `createOrUpdate()` and `firstOrCreate()` when a model conforms to `Timestampable`
- Keep all additions non-breaking and additive-only

**Non-Goals:**

- SQL-level aggregate optimization (SwiftData doesn't support it)
- Automatic timestamp management on every property mutation (SwiftData has no model-level hooks)
- Query builder / chainable API (deprioritized — see roadmap.md)
- Validation or callback frameworks

## Decisions

### 1. Aggregates live in Queryable, not a separate protocol

**Decision:** Add `sum`, `average`, and `pluck` as methods in the `Queryable` protocol extension.

**Rationale:** These are query operations, conceptually identical to `count` and `withMaxValue`. A separate `Aggregatable` protocol would force users to conform to two protocols for basic query functionality. Keeping them in `Queryable` means any model that already conforms gets the new methods for free.

**Alternative considered:** Separate `Aggregatable` protocol. Rejected — adds conformance ceremony for tightly related functionality.

### 2. sum uses AdditiveArithmetic, average uses BinaryInteger with Double return

**Decision:**
- `sum<V: AdditiveArithmetic>` — works with Int, Double, Float, and any custom type.
- `average<V: BinaryInteger>` returns `Double?` — returns nil on empty set rather than crashing on division by zero. Constrained to `BinaryInteger` because averaging floating-point types is trivial with `sum / count` and the `Double` conversion semantics differ.

**Rationale:** `AdditiveArithmetic` is the minimal constraint for summation (needs `+` and `.zero`). For average, returning `Double` avoids integer truncation surprises (average of `[1, 2]` should be `1.5`, not `1`).

**Alternative considered:** `average` returning `V` (same type). Rejected — integer division truncation is a footgun.

### 3. Find-or-create uses a closure, not a dictionary or default values

**Decision:** `firstOrCreate(where:in:create:)` takes a `() -> Self` closure for the create path.

**Rationale:** Type-safe, no runtime key-value parsing, works with any initializer the model provides. The closure is only called when no match is found, avoiding unnecessary allocation.

**Alternative considered:** Dictionary-based creation (like `Upsertable`). Rejected — requires `Decodable` conformance, which `Queryable` models may not have.

### 4. firstOrCreate inserts into context; firstOrInitialize does not

**Decision:** Two methods with different persistence behavior:
- `firstOrCreate` — calls `context.insert()` on the new model (consistent with `createOrUpdate`)
- `firstOrInitialize` — returns the new model without inserting (caller decides)

**Rationale:** Matches Rails semantics. Both return the model. Neither auto-saves (consistent with the entire library).

### 5. Timestampable is a standalone protocol, not part of Queryable or Upsertable

**Decision:** New `Timestampable` protocol extending `PersistentModel`. Integration with `Upsertable.createOrUpdate()` and `Queryable.firstOrCreate()` via conditional conformance checks (`if let timestampable = self as? Timestampable`).

**Rationale:** Timestamps are orthogonal to querying and upserting. A model might want timestamps without being `Upsertable`, or vice versa. The conditional integration keeps protocols decoupled.

**Alternative considered:** Making `Timestampable` extend `Upsertable`. Rejected — too coupled, and many models need timestamps without JSON upsert.

### 6. Auto-stamping is best-effort, not guaranteed

**Decision:** The library auto-stamps `createdAt`/`updatedAt` in its own methods (`createOrUpdate`, `firstOrCreate`). Direct `context.insert()` calls bypass auto-stamping — users must call `stampCreated()` manually.

**Rationale:** SwiftData has no model-level lifecycle hooks. Promising "automatic" timestamps when the library can't intercept all mutation paths would be misleading. Document the limitation clearly.

### 7. New source file for Timestampable, aggregates and find-or-create stay in Queryable.swift

**Decision:** Add aggregate and find-or-create methods to the existing `Queryable.swift`. Create a new `Timestampable.swift` for the timestamp protocol.

**Rationale:** Aggregates and find-or-create are `Queryable` features — splitting them into separate files would scatter related functionality. `Timestampable` is a new protocol and deserves its own file, following the existing pattern (`Queryable.swift`, `Upsertable.swift`).

## Risks / Trade-offs

**[Performance] In-memory aggregates on large datasets** → Mitigation: Document that `sum`, `average`, and `pluck` fetch all matching records into memory. For large datasets, users should use `FetchDescriptor` with limits or consider CoreData/SQLite directly. If SwiftData adds native aggregates in the future, the implementation can be swapped without API changes.

**[Correctness] average() on empty set** → Mitigation: Return `nil` instead of crashing on division by zero. Documented in spec.

**[Adoption] Timestampable requires property declarations** → Mitigation: Unlike `Queryable` (zero-boilerplate conformance), `Timestampable` requires models to declare `createdAt` and `updatedAt` stored properties. This is unavoidable — SwiftData models own their storage. Document with a clear conformance example.

**[Concurrency] KeyPath & Sendable constraints** → Mitigation: Follow the existing pattern in `withMaxValue`/`withMinValue` where keypath parameters are typed as `KeyPath<Self, V> & Sendable` for strict concurrency compliance.
