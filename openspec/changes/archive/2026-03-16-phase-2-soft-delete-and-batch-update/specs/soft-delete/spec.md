## ADDED Requirements

### Requirement: SoftDeletable protocol definition

The system SHALL define a `SoftDeletable` protocol constrained to `Queryable` requiring a mutable stored property `deletedAt: Date?`. Conformance SHALL require models to declare this property explicitly in their `@Model` class.

#### Scenario: Model conforms to SoftDeletable
- **WHEN** a `@Model` class declares `var deletedAt: Date?` and conforms to `SoftDeletable`
- **THEN** it SHALL compile and gain access to `softDelete()`, `restore()`, and trashed query methods

### Requirement: softDelete() sets deletedAt

The system SHALL provide a `softDelete()` instance method via protocol extension that sets `deletedAt` to `Date()`. The method SHALL NOT call `context.delete()`. The method SHALL NOT auto-save.

#### Scenario: Soft deleting a record
- **WHEN** `record.softDelete()` is called on a `SoftDeletable` model
- **THEN** `deletedAt` SHALL be set to the current date and the record SHALL remain in the context

#### Scenario: Soft deleting an already soft-deleted record
- **WHEN** `record.softDelete()` is called on a record where `deletedAt` is already set
- **THEN** `deletedAt` SHALL be updated to the current date (overwrite, not no-op)

### Requirement: restore() clears deletedAt

The system SHALL provide a `restore()` instance method via protocol extension that sets `deletedAt` to `nil`. The method SHALL NOT auto-save.

#### Scenario: Restoring a soft-deleted record
- **WHEN** `record.restore()` is called on a soft-deleted model
- **THEN** `deletedAt` SHALL be set to `nil`

#### Scenario: Restoring a non-deleted record
- **WHEN** `record.restore()` is called on a model where `deletedAt` is already `nil`
- **THEN** `deletedAt` SHALL remain `nil` (no-op, no error)

### Requirement: Auto-exclusion from standard queries

The `SoftDeletable` extension SHALL shadow `Queryable` default implementations for `all(in:)`, `first(in:)`, `count(in:)`, `exists(in:)`, and `deleteAll(in:)` to automatically exclude records where `deletedAt` is not `nil`.

#### Scenario: all(in:) excludes soft-deleted records
- **WHEN** `Model.all(in: context)` is called on a `SoftDeletable` type with 3 records, 1 soft-deleted
- **THEN** the result SHALL contain only the 2 non-deleted records

#### Scenario: first(in:) skips soft-deleted records
- **WHEN** `Model.first(in: context)` is called and the only record is soft-deleted
- **THEN** the result SHALL be `nil`

#### Scenario: count(in:) excludes soft-deleted records
- **WHEN** `Model.count(in: context)` is called with 3 records, 1 soft-deleted
- **THEN** the result SHALL be 2

#### Scenario: exists(in:) excludes soft-deleted records
- **WHEN** `Model.exists(in: context)` is called and all records are soft-deleted
- **THEN** the result SHALL be `false`

#### Scenario: Methods with explicit predicate do NOT auto-filter
- **WHEN** `Model.all(where: somePredicate, in: context)` is called on a `SoftDeletable` type
- **THEN** soft-deleted records matching the predicate SHALL be included (no auto-filtering)

### Requirement: deleteAll soft-deletes by default

The `SoftDeletable` extension SHALL shadow `deleteAll(in:)` and `deleteAll(where:in:)` to call `softDelete()` on each matching record instead of `context.delete()`.

#### Scenario: deleteAll soft-deletes records
- **WHEN** `Model.deleteAll(in: context)` is called on a `SoftDeletable` type with 3 records
- **THEN** all 3 records SHALL have `deletedAt` set and none SHALL be removed from the context

### Requirement: destroyAll for permanent deletion

The system SHALL provide `destroyAll(in:)` and `destroyAll(where:in:)` methods that permanently delete records using `context.delete()`, bypassing soft delete.

#### Scenario: destroyAll permanently removes records
- **WHEN** `Model.destroyAll(in: context)` is called on a `SoftDeletable` type
- **THEN** all records (including soft-deleted) SHALL be permanently removed from the context

### Requirement: withTrashed includes soft-deleted records

The system SHALL provide `allWithTrashed(in:)`, `countWithTrashed(in:)`, and `existsWithTrashed(in:)` methods that include soft-deleted records in results.

#### Scenario: allWithTrashed returns all records
- **WHEN** `Model.allWithTrashed(in: context)` is called with 3 records, 1 soft-deleted
- **THEN** the result SHALL contain all 3 records

#### Scenario: countWithTrashed counts all records
- **WHEN** `Model.countWithTrashed(in: context)` is called with 3 records, 1 soft-deleted
- **THEN** the result SHALL be 3

### Requirement: onlyTrashed returns only soft-deleted records

The system SHALL provide `allOnlyTrashed(in:)` and `countOnlyTrashed(in:)` methods that return only soft-deleted records.

#### Scenario: allOnlyTrashed returns only soft-deleted
- **WHEN** `Model.allOnlyTrashed(in: context)` is called with 3 records, 1 soft-deleted
- **THEN** the result SHALL contain only the 1 soft-deleted record

#### Scenario: countOnlyTrashed counts only soft-deleted
- **WHEN** `Model.countOnlyTrashed(in: context)` is called with 3 records, 1 soft-deleted
- **THEN** the result SHALL be 1
