# Queryable — Static Finder Protocol

## Purpose

Provide Active Record-style static query methods on any SwiftData `PersistentModel` type, eliminating the boilerplate of constructing `FetchDescriptor` for common operations.

## Inspiration

Maps directly to `NSManagedObject+AR_Finders` from [michalkonturek/ActiveRecord](https://github.com/michalkonturek/ActiveRecord):

| ActiveRecord (Obj-C)                        | SwiftDataRecord (Swift)                              |
|---------------------------------------------|------------------------------------------------------|
| `[Student objects]`                         | `Student.all(in: context)`                           |
| `[Student objects:@"age > 20"]`             | `Student.all(where: { $0.age > 20 }, in: context)`   |
| `[Student objects:@"age > 20" ordered:@"!age"]` | `Student.all(where: { $0.age > 20 }, sort: \.age, order: .reverse, in: context)` |
| `[Student ordered:@"lastName, age"]`        | `Student.all(sort: [SortDescriptor(\.lastName), SortDescriptor(\.age)], in: context)` |
| `[Student object:condition]`                | `Student.first(where: { ... }, in: context)`          |
| `[Student objectWithID:42]`                 | `Student.first(where: { $0.id == 42 }, in: context)` |
| `[Student count]`                           | `Student.count(in: context)`                          |
| `[Student count:@"age > 20"]`              | `Student.count(where: { $0.age > 20 }, in: context)` |
| `[Student hasObjects]`                      | `Student.exists(in: context)`                         |
| `[Student hasObjects:condition]`            | `Student.exists(where: { ... }, in: context)`         |
| `[Student objectWithMaxValueFor:@"age"]`    | `Student.max(\.age, in: context)`                    |
| `[Student objectWithMinValueFor:@"age"]`    | `Student.min(\.age, in: context)`                    |
| `[Student deleteAll]`                       | `Student.deleteAll(in: context)`                      |

## Specification

### Protocol Definition

The system SHALL define a `Queryable` protocol constrained to `PersistentModel`.

All methods SHALL be provided via protocol extension with default implementations so that conformance requires zero boilerplate — a model only needs to declare `extension MyModel: Queryable {}`.

### Query Methods

The system SHALL provide the following static methods:

#### Fetch All

- `static func all(in context: ModelContext) throws -> [Self]`
- `static func all(where predicate: Predicate<Self>, in context: ModelContext) throws -> [Self]`
- `static func all(where predicate: Predicate<Self>?, sort: SortDescriptor<Self>..., in context: ModelContext) throws -> [Self]`
- `static func all(where predicate: Predicate<Self>?, sort: [SortDescriptor<Self>], in context: ModelContext) throws -> [Self]`

All overloads SHALL delegate to a single internal implementation that builds a `FetchDescriptor<Self>`.

#### Fetch All with Limit/Offset

- `static func all(where predicate: Predicate<Self>?, sort: [SortDescriptor<Self>], limit: Int?, offset: Int?, in context: ModelContext) throws -> [Self]`

The `limit` parameter SHALL map to `FetchDescriptor.fetchLimit`.
The `offset` parameter SHALL map to `FetchDescriptor.fetchOffset`.

#### Fetch First

- `static func first(in context: ModelContext) throws -> Self?`
- `static func first(where predicate: Predicate<Self>, in context: ModelContext) throws -> Self?`

SHALL be implemented as `all(where:limit:1)` returning `.first`.

#### Count

- `static func count(in context: ModelContext) throws -> Int`
- `static func count(where predicate: Predicate<Self>, in context: ModelContext) throws -> Int`

SHALL use `ModelContext.fetchCount(_:)`.

#### Exists

- `static func exists(in context: ModelContext) throws -> Bool`
- `static func exists(where predicate: Predicate<Self>, in context: ModelContext) throws -> Bool`

SHALL be implemented as `count(where:) > 0`.

#### Aggregate Finders

- `static func withMaxValue<V: Comparable>(for keyPath: KeyPath<Self, V>, in context: ModelContext) throws -> Self?`
- `static func withMinValue<V: Comparable>(for keyPath: KeyPath<Self, V>, in context: ModelContext) throws -> Self?`

SHALL fetch all, then find the element with the max/min value using Swift standard library. If performance is a concern, this can be revisited with sorted fetch + limit 1.

#### Aggregate Queries

- `static func sum<V: AdditiveArithmetic>(for keyPath: KeyPath<Self, V> & Sendable, where predicate: Predicate<Self>? = nil, in context: ModelContext) throws -> V`
- `static func average<V: BinaryInteger>(for keyPath: KeyPath<Self, V> & Sendable, where predicate: Predicate<Self>? = nil, in context: ModelContext) throws -> Double?`
- `static func pluck<V>(_ keyPath: KeyPath<Self, V> & Sendable, where predicate: Predicate<Self>? = nil, in context: ModelContext) throws -> [V]`

`sum` SHALL return `V.zero` for empty sets. `average` SHALL return `nil` for empty sets. `pluck` SHALL return an empty array for empty sets. See `openspec/specs/aggregates/spec.md` for detailed requirements.

#### Find or Create

- `static func firstOrCreate(where predicate: Predicate<Self>, in context: ModelContext, create: () -> Self) throws -> Self`
- `static func firstOrInitialize(where predicate: Predicate<Self>, in context: ModelContext, create: () -> Self) throws -> Self`

`firstOrCreate` SHALL insert the new record into the context. `firstOrInitialize` SHALL NOT insert. Neither SHALL auto-save. See `openspec/specs/find-or-create/spec.md` for detailed requirements.

#### Batch Update

- `static func updateAll(where predicate: Predicate<Self>? = nil, in context: ModelContext, apply: (Self) -> Void) throws`

SHALL fetch matching records and apply the mutation closure to each. SHALL NOT auto-save. Empty set is a no-op. See `openspec/specs/batch-update/spec.md` for detailed requirements.

#### Validatable Integration

When a model conforms to both `Queryable` and `Validatable`, the `firstOrCreate(where:in:create:)` method SHALL call `validate()` on newly created models before insertion. If validation fails, the model SHALL NOT be inserted and `ValidationError` SHALL be thrown. Existing matched models SHALL NOT be validated.

#### Delete All

- `static func deleteAll(in context: ModelContext) throws`
- `static func deleteAll(where predicate: Predicate<Self>, in context: ModelContext) throws`

SHALL fetch matching objects and call `context.delete(_:)` on each. SHALL NOT auto-save; the caller decides when to save.

### Design Constraints

- All methods SHALL accept `ModelContext` as an explicit parameter. No ambient/global context.
- All methods SHALL be `throws`. No force-try, no silent error swallowing.
- Predicate parameters SHALL use Swift's `#Predicate` macro type (`Foundation.Predicate<Self>`).
- Sort parameters SHALL use `SortDescriptor<Self>` from SwiftData.
- The protocol SHALL NOT require any associated types or type erasure.

### Edge Cases

- Calling `all()` on a type with zero stored objects SHALL return an empty array, not nil.
- Calling `first()` on a type with zero stored objects SHALL return nil.
- Calling `deleteAll()` on a type with zero stored objects SHALL be a no-op (no error).
- All methods SHALL work with any `ModelContext` (main actor or background).

## Verification

- Unit tests SHALL cover each method with at least: empty store, single object, multiple objects.
- Tests SHALL verify predicate filtering returns correct subset.
- Tests SHALL verify sort ordering (ascending and descending).
- Tests SHALL verify limit and offset behavior.
- Tests SHALL verify `deleteAll` removes only matching objects when a predicate is provided.
- Tests SHALL use an in-memory `ModelContainer` for isolation.
