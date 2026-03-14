## ADDED Requirements

### Requirement: Find existing or create new record

The system SHALL provide a static method `firstOrCreate(where:in:create:)` on `Queryable` that returns the first record matching the predicate, or creates and inserts a new one using the provided closure if no match exists. The method SHALL be marked `@discardableResult`. The create closure SHALL only be called when no match is found. The new record SHALL be inserted into the context via `context.insert()`. The method SHALL NOT auto-save the context.

#### Scenario: Record exists
- **WHEN** `Student.firstOrCreate(where: #Predicate { $0.uid == 1 }, in: context) { Student(uid: 1, ...) }` is called and a student with uid 1 exists
- **THEN** the existing student SHALL be returned and the create closure SHALL NOT be called

#### Scenario: Record does not exist
- **WHEN** `Student.firstOrCreate(where: #Predicate { $0.uid == 99 }, in: context) { Student(uid: 99, ...) }` is called and no student with uid 99 exists
- **THEN** a new student SHALL be created via the closure, inserted into the context, and returned

#### Scenario: Does not auto-save
- **WHEN** `firstOrCreate` creates a new record
- **THEN** the context SHALL have unsaved changes (the method SHALL NOT call `context.save()`)

### Requirement: Find existing or initialize without persisting

The system SHALL provide a static method `firstOrInitialize(where:in:create:)` on `Queryable` that returns the first record matching the predicate, or creates a new one using the provided closure WITHOUT inserting it into the context. The create closure SHALL only be called when no match is found.

#### Scenario: Record exists
- **WHEN** `Student.firstOrInitialize(where: #Predicate { $0.uid == 1 }, in: context) { Student(uid: 1, ...) }` is called and a student with uid 1 exists
- **THEN** the existing student SHALL be returned

#### Scenario: Record does not exist — not inserted
- **WHEN** `Student.firstOrInitialize(where: #Predicate { $0.uid == 99 }, in: context) { Student(uid: 99, ...) }` is called and no student with uid 99 exists
- **THEN** a new student SHALL be created via the closure and returned, but SHALL NOT be inserted into the context

#### Scenario: Caller can insert later
- **WHEN** `firstOrInitialize` returns a new (non-persisted) record
- **THEN** the caller SHALL be able to insert it manually via `context.insert(record)` at any time
