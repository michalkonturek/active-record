## ADDED Requirements

### Requirement: updateAll with mutation closure

The system SHALL provide a static method `updateAll(where:in:apply:)` on `Queryable` that fetches all records matching an optional predicate and applies a mutation closure to each. The method SHALL NOT auto-save. When no predicate is provided, all records SHALL be included.

#### Scenario: Update all records
- **WHEN** `Student.updateAll(in: context) { $0.age += 1 }` is called with 3 students
- **THEN** all 3 students SHALL have their age incremented by 1

#### Scenario: Update with predicate
- **WHEN** `Student.updateAll(where: #Predicate { $0.age >= 18 }, in: context) { $0.status = "adult" }` is called
- **THEN** only students with age >= 18 SHALL be mutated

#### Scenario: Update on empty set
- **WHEN** `Student.updateAll(in: context) { $0.age += 1 }` is called with no students
- **THEN** no error SHALL be thrown (no-op)

#### Scenario: Does not auto-save
- **WHEN** `updateAll` mutates records
- **THEN** the context SHALL have unsaved changes (the method SHALL NOT call `context.save()`)
