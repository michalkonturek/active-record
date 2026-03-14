# Roadmap

Planned features, priorities, and rough sequencing for active-record.

## Phased Rollout

### Phase 1 — Quick Wins (single release)

| # | Feature | Effort | Value | Status |
|---|---------|--------|-------|--------|
| 1 | More Aggregates (sum, average, pluck) | Low | Medium | Planned |
| 2 | Find or Create | Low | High | Planned |
| 3 | Timestamps (Timestampable) | Low | Medium | Planned |

### Phase 2 — Medium Effort (one feature per release)

| # | Feature | Effort | Value | Status |
|---|---------|--------|-------|--------|
| 4 | Soft Delete (SoftDeletable) | Medium | High | Planned — needs spike |
| 5 | Batch updateAll | Medium | Medium | Planned |

### Phase 3 — Needs Spikes / Lower Priority

| # | Feature | Effort | Value | Status |
|---|---------|--------|-------|--------|
| 6 | Validations (Validatable) | High | Medium | Planned |

### Deprioritized

| Feature | Reason |
|---------|--------|
| Chainable Query Builder | SwiftData's `#Predicate` macro is compile-time; predicates cannot be composed dynamically (no `&&` / `\|\|` on `Predicate`). A builder can only compose sort/limit/offset, which the existing API already handles. Named scopes (static computed predicates) achieve the same ergonomics with zero new infrastructure — document the pattern instead. |
| Callbacks / Lifecycle Hooks | SwiftData has no per-model `willSave`/`didSave`. Hooks would only fire through library methods (e.g. `deleteAll`, `createOrUpdate`), not direct `context.delete()` / `context.insert()` calls. Leaky abstraction — skip. |

---

## Feature Details

### 1. More Aggregates

Extend `Queryable` with additional aggregate queries.

**SwiftData constraint:** No SQL-level aggregates (`SELECT SUM(...)`). All implementations fetch models and compute in-memory via `map` + `reduce`. Still valuable for ergonomics, and can be optimized transparently if SwiftData adds native aggregates later.

**API signatures:**

```swift
// sum — constrained to AdditiveArithmetic (Int, Double, etc.)
static func sum<V: AdditiveArithmetic>(
    for keyPath: KeyPath<Self, V> & Sendable,
    where predicate: Predicate<Self>? = nil,
    in context: ModelContext
) throws -> V

// average — always returns Double, nil if empty
static func average<V: BinaryInteger>(
    for keyPath: KeyPath<Self, V> & Sendable,
    where predicate: Predicate<Self>? = nil,
    in context: ModelContext
) throws -> Double?

// pluck — extract a single field as [T]
static func pluck<V>(
    _ keyPath: KeyPath<Self, V>,
    where predicate: Predicate<Self>? = nil,
    in context: ModelContext
) throws -> [V]
```

**Implementation:** fetch all (or filtered) → map keypath → reduce/collect.

### 2. Find or Create

Convenience finders that create when no match exists.

**API design:** Use a closure for the create path (type-safe, no dictionaries):

```swift
// Inserts into context but does NOT auto-save (consistent with createOrUpdate)
@discardableResult
static func firstOrCreate(
    where predicate: Predicate<Self>,
    in context: ModelContext,
    create: () -> Self
) throws -> Self

// Same but does NOT insert — caller decides when to persist
static func firstOrInitialize(
    where predicate: Predicate<Self>,
    in context: ModelContext,
    create: () -> Self
) throws -> Self
```

**Flow:**

```
Predicate → first(where:) → found? → return existing
                           → nil?   → call create closure
                                      insert (firstOrCreate only)
                                      return new record
```

### 3. Timestamps (Timestampable)

**SwiftData constraint:** No per-model lifecycle hooks. Cannot truly auto-set `updatedAt` on every mutation.

**Pragmatic approach — honest scope:**

```swift
public protocol Timestampable: PersistentModel {
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}

extension Timestampable {
    /// Sets updatedAt to now. Call after mutations.
    public func touch()

    /// Sets both createdAt and updatedAt to now. Call on creation.
    public func stampCreated()
}
```

**Auto-stamping where possible:**
- `createOrUpdate()` (Upsertable) can auto-call `stampCreated()` when `Self: Timestampable`
- `firstOrCreate()` can auto-call `stampCreated()` on the create path
- All other mutations: user calls `touch()` explicitly

**Don't promise "automatic" — promise "convenient."**

### 4. Soft Delete (SoftDeletable)

**Requires spike:** Verify that `#Predicate { $0.deletedAt == nil }` compiles in a protocol extension where `Self: SoftDeletable`. If SwiftData's `#Predicate` macro can't resolve `\.deletedAt` on a protocol-constrained generic, need a workaround (e.g. conformers provide a static `notDeletedPredicate`).

**API surface (if spike succeeds):**

```swift
public protocol SoftDeletable: Queryable {
    var deletedAt: Date? { get set }
}

extension SoftDeletable {
    // Instance methods
    func softDelete()              // sets deletedAt = Date()
    func restore()                 // sets deletedAt = nil

    // Overrides Queryable methods to exclude soft-deleted by default
    static func all(in:) throws -> [Self]
    static func first(in:) throws -> Self?
    static func count(in:) throws -> Int

    // Escape hatches
    static func withTrashed(...) throws -> [Self]    // includes soft-deleted
    static func onlyTrashed(...) throws -> [Self]    // only soft-deleted
}
```

### 5. Batch updateAll

**SwiftData constraint:** No bulk SQL UPDATE. Implementation fetches models and mutates each one in-memory. Still valuable as ergonomic sugar.

```swift
static func updateAll(
    where predicate: Predicate<Self>? = nil,
    in context: ModelContext,
    apply: (Self) -> Void
) throws
```

**Example:**
```swift
try Student.updateAll(where: #Predicate { $0.age >= 18 }, in: context) { student in
    student.status = "adult"
}
```

### 6. Validations (Validatable)

**Keep minimal** — just the protocol contract. Swift's type system already handles most compile-time safety. Focus on runtime constraints (string length, numeric ranges, cross-field validation).

```swift
public protocol Validatable: PersistentModel {
    func validate() throws
}
```

Let users implement `validate()` with plain Swift code. Don't build a rules DSL — let the community do that if there's demand.

---

## Named Scopes Pattern (documentation, not code)

Instead of a query builder, document this pattern for reusable query fragments:

```swift
extension Student {
    static var adults: Predicate<Student> {
        #Predicate { $0.age >= 18 }
    }
    static var nameAscending: SortDescriptor<Student> {
        SortDescriptor(\.lastName)
    }
}

// Usage — works with existing Queryable API:
try Student.all(where: Student.adults, sort: Student.nameAscending, in: context)
```
