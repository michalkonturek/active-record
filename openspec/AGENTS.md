# SwiftDataRecord — Agent Instructions

## Project Context

This is a Swift Package Manager library called **SwiftDataRecord** that brings Active Record-style ergonomics to Apple's SwiftData framework. It is inspired by [michalkonturek/ActiveRecord](https://github.com/michalkonturek/ActiveRecord), a Core Data Active Record library in Objective-C.

Read `openspec/project.md` for full project context before starting any work.

## Specs Location

All specifications live in `openspec/specs/`. Read the relevant spec before implementing:

- `openspec/specs/queryable/spec.md` — Static finder/query protocol
- `openspec/specs/upsertable/spec.md` — JSON-based create-or-update protocol
- `openspec/specs/package-structure/spec.md` — SPM layout, targets, error types, test models

## Key Constraints

1. **Swift 6.0 strict concurrency.** All code must compile cleanly under strict concurrency checking. Use `@MainActor` where required by SwiftData, use `Sendable` conformance where appropriate.
2. **No external dependencies.** Only `SwiftData` and `Foundation`.
3. **Context-explicit API.** Every public method takes a `ModelContext` parameter. No singletons, no ambient context.
4. **Protocol extensions only.** No base classes. Conformance should require minimal boilerplate from the consumer.
5. **Throwing by default.** All persistence operations use `throws`. No silent failures.
6. **Tests use Swift Testing** (`import Testing`), not XCTest. Use `@Test` and `#expect` macros.
7. **In-memory containers** for all tests. Each test gets a fresh `ModelContainer`.

## Implementation Order

1. Package.swift and folder structure
2. `Errors.swift` — error enum
3. `Queryable.swift` — protocol + extension with all static finders
4. Test models (Student, Course, Module)
5. `QueryableTests.swift` — full test coverage for Queryable
6. `Upsertable.swift` — protocol + extension with upsert logic
7. `UpsertableTests.swift` — full test coverage for Upsertable
8. README.md

## Style

- Public API should feel natural to a Swift developer familiar with SwiftData.
- Prefer clarity over brevity in method signatures.
- Document all public types and methods with `///` doc comments.
- Follow Swift API Design Guidelines naming conventions.
