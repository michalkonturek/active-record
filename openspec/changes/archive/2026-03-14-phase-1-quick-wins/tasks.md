## 1. Aggregates

- [x] 1.1 Add `sum(for:where:in:)` method to `Queryable` extension in `Queryable.swift` — constrained to `AdditiveArithmetic & Sendable`, returns `V.zero` for empty sets
- [x] 1.2 Add `average(for:where:in:)` method to `Queryable` extension — constrained to `BinaryInteger & Sendable`, returns `Double?` (nil for empty sets)
- [x] 1.3 Add `pluck(_:where:in:)` method to `Queryable` extension — returns `[V]`, empty array for empty sets
- [x] 1.4 Write tests for `sum`: all ages, filtered sum, empty set returns zero
- [x] 1.5 Write tests for `average`: all ages, non-integer result (1.5 not 1), empty set returns nil
- [x] 1.6 Write tests for `pluck`: all first names, filtered pluck, empty set returns empty array

## 2. Find or Create

- [x] 2.1 Add `firstOrCreate(where:in:create:)` method to `Queryable` extension — `@discardableResult`, inserts via `context.insert()`, does not auto-save
- [x] 2.2 Add `firstOrInitialize(where:in:create:)` method to `Queryable` extension — returns model without inserting into context
- [x] 2.3 Write tests for `firstOrCreate`: record exists (returns existing), record missing (creates and inserts), does not auto-save
- [x] 2.4 Write tests for `firstOrInitialize`: record exists (returns existing), record missing (creates but does not insert)

## 3. Timestampable

- [x] 3.1 Create `Timestampable.swift` with protocol definition (`createdAt: Date`, `updatedAt: Date`) constrained to `PersistentModel`
- [x] 3.2 Implement `touch()` method in protocol extension — sets `updatedAt` to `Date()`
- [x] 3.3 Implement `stampCreated()` method in protocol extension — sets both `createdAt` and `updatedAt` to `Date()`
- [x] 3.4 Create a `Timestampable`-conforming test model (e.g., `TimestampedStudent` or add conformance to existing model)
- [x] 3.5 Write tests for `touch()`: updatedAt changes, createdAt unchanged
- [x] 3.6 Write tests for `stampCreated()`: both timestamps set to same date

## 4. Timestamp Auto-Stamping Integration

- [x] 4.1 Add auto-stamp to `Upsertable.createOrUpdate(from:using:in:)` — call `stampCreated()` after insert when `Self: Timestampable`
- [x] 4.2 Add auto-stamp to `Upsertable.createOrUpdate(fromArray:using:in:)` — same conditional stamping for batch upserts
- [x] 4.3 Add auto-stamp to `Queryable.firstOrCreate(where:in:create:)` — call `stampCreated()` on create path only (not when returning existing)
- [x] 4.4 Write tests for auto-stamp in `createOrUpdate`: timestamps set on upserted model
- [x] 4.5 Write tests for auto-stamp in `firstOrCreate`: timestamps set on new model, NOT modified on existing match
- [x] 4.6 Verify non-Timestampable models are unaffected (existing tests still pass)

## 5. Final Verification

- [x] 5.1 Run full test suite — `swift test` — all tests pass
- [x] 5.2 Run `swift build` — no warnings or errors
