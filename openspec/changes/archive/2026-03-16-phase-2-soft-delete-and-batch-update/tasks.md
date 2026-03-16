## 1. Spike: #Predicate in protocol extension

- [x] 1.1 Write a minimal spike to test if `#Predicate<Self> { $0.deletedAt == nil }` compiles in a `SoftDeletable` protocol extension. If it fails, determine which fallback approach to use (post-fetch filtering or conformer-provided predicate).

## 2. SoftDeletable Protocol

- [x] 2.1 Create `SoftDeletable.swift` with protocol definition extending `Queryable`, requiring `var deletedAt: Date?`
- [x] 2.2 Implement `softDelete()` instance method — sets `deletedAt = Date()`
- [x] 2.3 Implement `restore()` instance method — sets `deletedAt = nil`

## 3. SoftDeletable Query Overrides

- [x] 3.1 Shadow `all(in:)` to exclude soft-deleted records (using spike result for filtering approach)
- [x] 3.2 Shadow `first(in:)` to exclude soft-deleted records
- [x] 3.3 Shadow `count(in:)` to exclude soft-deleted records
- [x] 3.4 Shadow `exists(in:)` to exclude soft-deleted records
- [x] 3.5 Shadow `deleteAll(in:)` and `deleteAll(where:in:)` to soft-delete instead of hard delete

## 4. SoftDeletable Escape Hatches

- [x] 4.1 Implement `destroyAll(in:)` and `destroyAll(where:in:)` for permanent deletion
- [x] 4.2 Implement `allWithTrashed(in:)`, `countWithTrashed(in:)`, `existsWithTrashed(in:)`
- [x] 4.3 Implement `allOnlyTrashed(in:)`, `countOnlyTrashed(in:)`

## 5. SoftDeletable Tests

- [x] 5.1 Create `SoftDeletable`-conforming test model (e.g., `Task` or `Post` with `deletedAt`)
- [x] 5.2 Write tests for `softDelete()`: sets deletedAt, record stays in context
- [x] 5.3 Write tests for `restore()`: clears deletedAt, no-op on non-deleted
- [x] 5.4 Write tests for auto-exclusion: `all`, `first`, `count`, `exists` skip soft-deleted
- [x] 5.5 Write tests for `deleteAll` soft-deletes instead of hard-deletes
- [x] 5.6 Write tests for `destroyAll`: permanently removes records
- [x] 5.7 Write tests for `allWithTrashed`, `countWithTrashed`, `existsWithTrashed`
- [x] 5.8 Write tests for `allOnlyTrashed`, `countOnlyTrashed`
- [x] 5.9 Write test verifying `all(where:in:)` with explicit predicate does NOT auto-filter

## 6. Batch updateAll

- [x] 6.1 Add `updateAll(where:in:apply:)` method to `Queryable` extension in `Queryable.swift`
- [x] 6.2 Write tests for `updateAll`: all records, filtered, empty set (no-op), does not auto-save

## 7. Final Verification

- [x] 7.1 Run full test suite — `swift test` — all tests pass
- [x] 7.2 Run `swift build` — no warnings or errors
