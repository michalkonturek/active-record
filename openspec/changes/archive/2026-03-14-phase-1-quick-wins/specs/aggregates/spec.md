## ADDED Requirements

### Requirement: Sum numeric values across records

The system SHALL provide a static method `sum(for:where:in:)` on `Queryable` that returns the sum of a numeric keypath across all matching records. The keypath type SHALL be constrained to `AdditiveArithmetic & Sendable`. When no predicate is provided, all records SHALL be included. When no records match, the method SHALL return `V.zero`.

#### Scenario: Sum all ages
- **WHEN** `Student.sum(for: \.age, in: context)` is called with 3 students aged 20, 25, 30
- **THEN** the result SHALL be 75

#### Scenario: Sum with predicate
- **WHEN** `Student.sum(for: \.age, where: #Predicate { $0.age > 20 }, in: context)` is called
- **THEN** only students with age > 20 SHALL be included in the sum

#### Scenario: Sum on empty set
- **WHEN** `Student.sum(for: \.age, in: context)` is called with no students in the store
- **THEN** the result SHALL be `Int.zero` (0)

### Requirement: Average numeric values across records

The system SHALL provide a static method `average(for:where:in:)` on `Queryable` that returns the average of a `BinaryInteger` keypath as `Double?`. When no records match, the method SHALL return `nil`. The method SHALL NOT crash on division by zero.

#### Scenario: Average all ages
- **WHEN** `Student.average(for: \.age, in: context)` is called with students aged 20 and 25
- **THEN** the result SHALL be `22.5`

#### Scenario: Average with non-integer result
- **WHEN** `Student.average(for: \.age, in: context)` is called with students aged 1 and 2
- **THEN** the result SHALL be `1.5` (not truncated to 1)

#### Scenario: Average on empty set
- **WHEN** `Student.average(for: \.age, in: context)` is called with no students in the store
- **THEN** the result SHALL be `nil`

### Requirement: Pluck single field values

The system SHALL provide a static method `pluck(_:where:in:)` on `Queryable` that extracts the values of a single keypath from all matching records, returning `[V]`. When no records match, the method SHALL return an empty array.

#### Scenario: Pluck all first names
- **WHEN** `Student.pluck(\.firstName, in: context)` is called with students "Alice", "Bob", "Carol"
- **THEN** the result SHALL be an array containing "Alice", "Bob", "Carol"

#### Scenario: Pluck with predicate
- **WHEN** `Student.pluck(\.firstName, where: #Predicate { $0.age > 20 }, in: context)` is called
- **THEN** only first names of students with age > 20 SHALL be included

#### Scenario: Pluck on empty set
- **WHEN** `Student.pluck(\.firstName, in: context)` is called with no students in the store
- **THEN** the result SHALL be an empty array
