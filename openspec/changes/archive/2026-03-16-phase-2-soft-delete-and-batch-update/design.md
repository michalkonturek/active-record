## Context

The library provides `Queryable` and `Upsertable` protocols on SwiftData's `PersistentModel`. All methods are static, take explicit `ModelContext`, and never auto-save. Phase 1 (v1.1.0) added aggregates, find-or-create, and `Timestampable`.

SwiftData's `#Predicate` macro resolves keypaths at compile time. A critical question for `SoftDeletable` is whether `#Predicate { $0.deletedAt == nil }` compiles in a protocol extension where `Self` is constrained to `SoftDeletable`. This must be spiked before implementation.

## Goals / Non-Goals

**Goals:**

- Add `SoftDeletable` protocol that auto-excludes soft-deleted records from standard `Queryable` queries
- Provide `softDelete()`, `restore()`, `withTrashed`, and `onlyTrashed` methods
- Add `updateAll(where:in:apply:)` to `Queryable` for bulk mutations
- Keep all additions non-breaking and additive-only

**Non-Goals:**

- Hard delete cascade (soft-deleting a parent does not cascade to children)
- Auto-purge of old soft-deleted records (scheduled cleanup)
- SQL-level bulk UPDATE optimization (SwiftData doesn't support it)
- Soft delete integration with `Upsertable` (upserting a soft-deleted record is out of scope for now)

## Decisions

### 1. SoftDeletable extends Queryable

**Decision:** `SoftDeletable` protocol requires `Queryable` conformance and adds `var deletedAt: Date? { get set }`.

**Rationale:** Soft delete is fundamentally about modifying query behavior. Requiring `Queryable` ensures all the query methods are available to override. Models that want soft delete without querying don't make sense.

### 2. Spike-first approach for #Predicate in protocol extensions

**Decision:** The first implementation task is a spike to verify `#Predicate { $0.deletedAt == nil }` compiles in a `SoftDeletable` extension. If it fails, fall back to post-fetch filtering.

**Approach A (preferred — predicate-level filtering):**
```swift
extension SoftDeletable {
    public static func all(in context: ModelContext) throws -> [Self] {
        try all(where: #Predicate { $0.deletedAt == nil }, in: context)
    }
}
```

**Approach B (fallback — post-fetch filtering):**
```swift
extension SoftDeletable {
    public static func all(in context: ModelContext) throws -> [Self] {
        try Queryable.all(in: context).filter { $0.deletedAt == nil }
    }
}
```

**Approach C (fallback — conformer-provided predicate):**
```swift
protocol SoftDeletable: Queryable {
    var deletedAt: Date? { get set }
    static var notDeletedPredicate: Predicate<Self> { get }
}
```

Approach A is cleanest (DB-level filtering). Approach B works but loads all records. Approach C adds conformance burden. The spike determines which path we take.

### 3. SoftDeletable overrides Queryable methods via protocol extension shadowing

**Decision:** Provide new `all(in:)`, `first(in:)`, `count(in:)`, `exists(in:)`, and `deleteAll(in:)` in a `SoftDeletable` extension that shadow the `Queryable` defaults. These filter out soft-deleted records automatically.

**Rationale:** Swift's protocol extension dispatch means that when a type conforms to `SoftDeletable`, the more specific extension methods are called. This gives automatic exclusion without any changes to `Queryable` itself.

**Important caveat:** Methods called with an explicit predicate (`all(where:in:)`) do NOT auto-filter. Users who pass their own predicate are responsible for including soft-delete logic. This matches Rails behavior where scopes don't compose automatically with `unscoped` queries.

### 4. withTrashed and onlyTrashed as separate methods

**Decision:** Provide `allWithTrashed(in:)`, `allOnlyTrashed(in:)`, `countWithTrashed(in:)`, etc. as distinct method names rather than a parameter flag.

**Rationale:** Adding a `includeTrashed: Bool` parameter to every `Queryable` method would pollute the API for all models, not just soft-deletable ones. Separate methods keep the API clean and only appear on `SoftDeletable` types.

**Alternative considered:** An `includeTrashed` parameter. Rejected — changes `Queryable` API surface for all models.

### 5. softDelete() sets deletedAt; restore() clears it

**Decision:** Instance methods on the model, not static methods. `softDelete()` sets `deletedAt = Date()`. `restore()` sets `deletedAt = nil`. Neither auto-saves.

**Rationale:** Consistent with `touch()` and `stampCreated()` on `Timestampable` — instance methods that mutate the model, caller decides when to save.

### 6. deleteAll on SoftDeletable soft-deletes by default

**Decision:** Override `deleteAll(in:)` on `SoftDeletable` to call `softDelete()` on each record instead of `context.delete()`. Provide `destroyAll(in:)` for permanent deletion.

**Rationale:** If a model opts into soft delete, bulk delete should respect that. `destroyAll` is the escape hatch for hard delete, matching Rails conventions (`destroy` vs `delete`).

### 7. updateAll lives in Queryable, not a separate protocol

**Decision:** Add `updateAll(where:in:apply:)` as a static method in the `Queryable` extension.

**Rationale:** It's a query-then-mutate operation, logically part of `Queryable`. No new protocol needed for a single method.

### 8. New SoftDeletable.swift file; updateAll in Queryable.swift

**Decision:** `SoftDeletable` gets its own file (new protocol). `updateAll` is added to `Queryable.swift` (extends existing protocol).

**Rationale:** Follows the existing pattern: one file per protocol (`Queryable.swift`, `Upsertable.swift`, `Timestampable.swift`).

## Risks / Trade-offs

**[Spike] #Predicate may not work in protocol extensions** → Mitigation: Spike is the first task. If it fails, fall back to post-fetch filtering (Approach B) which is functionally correct but loads all records into memory. Document the performance implication.

**[Shadowing] Protocol extension dispatch is static, not dynamic** → Mitigation: When a variable is typed as `any Queryable` rather than a concrete type, the `Queryable` default (not the `SoftDeletable` override) will be called. Document that soft-delete filtering only applies when the concrete type is known at compile time. This is a Swift language limitation, not a library bug.

**[API surface] Predicate-taking methods don't auto-filter** → Mitigation: Document clearly that `all(where:in:)` with a custom predicate does NOT auto-exclude soft-deleted records. Users must add `&& $0.deletedAt == nil` to their predicate if needed. This matches Rails behavior.

**[Performance] updateAll fetches all records** → Mitigation: SwiftData has no bulk UPDATE. Document that `updateAll` loads all matching models into memory. For very large datasets, users should use `FetchDescriptor` with limits and batch manually.
