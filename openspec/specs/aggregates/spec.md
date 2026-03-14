# Aggregates — Sum, Average, Pluck

## Purpose

Provide numeric aggregation and single-field extraction methods on `Queryable`, extending the existing aggregate finders (`withMaxValue`, `withMinValue`).

## Specification

### Sum numeric values across records

The system SHALL provide a static method `sum(for:where:in:)` on `Queryable` that returns the sum of a numeric keypath across all matching records. The keypath type SHALL be constrained to `AdditiveArithmetic & Sendable`. When no predicate is provided, all records SHALL be included. When no records match, the method SHALL return `V.zero`.

### Average numeric values across records

The system SHALL provide a static method `average(for:where:in:)` on `Queryable` that returns the average of a `BinaryInteger` keypath as `Double?`. When no records match, the method SHALL return `nil`. The method SHALL NOT crash on division by zero.

### Pluck single field values

The system SHALL provide a static method `pluck(_:where:in:)` on `Queryable` that extracts the values of a single keypath from all matching records, returning `[V]`. When no records match, the method SHALL return an empty array.

## Verification

- Unit tests SHALL verify sum with all records, filtered sum, and empty set (returns zero).
- Unit tests SHALL verify average with all records, non-integer result (1.5 not 1), and empty set (returns nil).
- Unit tests SHALL verify pluck with all records, filtered pluck, and empty set (returns empty array).
- Tests SHALL use an in-memory `ModelContainer` for isolation.
