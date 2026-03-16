# Package Structure

## Purpose

Define the Swift Package Manager layout, targets, and module organization for active-record.

## Specification

### Package Name

`active-record` (repository and SPM package name). Library target and module name: `ActiveRecord`.

### Repository Layout

```
active-record/
├── Package.swift
├── README.md
├── CHANGELOG.md
├── CLAUDE.md
├── LICENSE
├── roadmap.md
├── openspec/
│   ├── project.md
│   ├── config.yaml
│   ├── specs/
│   │   ├── aggregates/spec.md
│   │   ├── batch-update/spec.md
│   │   ├── find-or-create/spec.md
│   │   ├── package-structure/spec.md
│   │   ├── queryable/spec.md
│   │   ├── soft-delete/spec.md
│   │   ├── timestampable/spec.md
│   │   └── upsertable/spec.md
│   └── changes/
│       └── archive/
├── Sources/
│   └── ActiveRecord/
│       ├── Errors.swift             # ActiveRecordError enum
│       ├── Queryable.swift          # Queryable protocol + extension
│       ├── SoftDeletable.swift      # SoftDeletable protocol + extension
│       ├── Timestampable.swift      # Timestampable protocol + extension
│       └── Upsertable.swift         # Upsertable protocol + extension
├── Demo/
│   ├── main.swift                   # Demo executable entry point
│   └── Models/
│       ├── Todo.swift               # Queryable + Upsertable demo model
│       └── Post.swift               # SoftDeletable demo model
└── Tests/
    └── active-record-tests/
        ├── Models/
        │   ├── Student.swift        # Queryable + Upsertable test model
        │   ├── Course.swift         # Queryable + Upsertable test model
        │   ├── Module.swift         # Queryable + Upsertable test model
        │   ├── Article.swift        # Queryable + Upsertable + Timestampable test model
        │   └── Post.swift           # SoftDeletable test model
        ├── Helpers/
        │   └── TestContainer.swift  # In-memory ModelContainer factory
        ├── QueryableTests.swift
        ├── UpsertableTests.swift
        ├── AggregateTests.swift
        ├── FindOrCreateTests.swift
        ├── TimestampableTests.swift
        ├── SoftDeletableTests.swift
        └── UpdateAllTests.swift
```

### Package.swift

```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "active-record",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "ActiveRecord",
            targets: ["ActiveRecord"]
        )
    ],
    targets: [
        .target(
            name: "ActiveRecord"
        ),
        .executableTarget(
            name: "demo",
            dependencies: ["ActiveRecord"],
            path: "Demo"
        ),
        .testTarget(
            name: "active-record-tests",
            dependencies: ["ActiveRecord"]
        )
    ]
)
```

### Design Decisions

- **Single target.** No sub-modules. The library is small enough that splitting protocols into separate targets adds complexity without benefit. Users import one module: `import ActiveRecord`.
- **Zero external dependencies.** Only system frameworks: `SwiftData` and `Foundation`.
- **Swift 6.0 tools version.** Required for strict concurrency checking and latest SwiftData APIs.
- **Platform minimums.** iOS 17 / macOS 14 — the minimum for SwiftData availability.
- **Demo executable target.** Separate `demo` target with models in their own files (required to avoid Swift 6.1 compiler crash with multiple `@Model` types in entry point file).
- **PascalCase module name.** Library target is `ActiveRecord` (not `active-record`) following Swift naming conventions. The package name remains `active-record` for URL compatibility.

### Error Type

The system SHALL define a single error enum:

```swift
public enum ActiveRecordError: Error, LocalizedError {
    case missingPrimaryKey(type: String, key: String)
    case decodingFailed(type: String, underlying: Error)
}
```

- `missingPrimaryKey` — thrown when JSON data lacks the expected primary key field during upsert.
- `decodingFailed` — wraps `DecodingError` with the model type name for better diagnostics.

### Test Models

- **Student** — has `uid: Int`, `firstName: String`, `lastName: String`, `age: Int`. Has a to-one relationship to `Course` and a to-many relationship to `[Module]`. Conforms to `Queryable` and `Upsertable`.
- **Course** — has `uid: Int`, `name: String`. Conforms to `Queryable` and `Upsertable`.
- **Module** — has `uid: Int`, `name: String`. Conforms to `Queryable` and `Upsertable`.
- **Article** — has `uid: Int`, `title: String`, `createdAt: Date`, `updatedAt: Date`. Conforms to `Queryable`, `Upsertable`, and `Timestampable`.
- **Post** — has `uid: Int`, `title: String`, `deletedAt: Date?`. Conforms to `SoftDeletable`. Uses its own isolated `ModelContainer` in tests to avoid SwiftData concurrency issues with destructive operations.

### Test Container Helper

```swift
@MainActor
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: Student.self, Course.self, Module.self, Article.self,
        configurations: config
    )
}
```

All tests SHALL use in-memory containers for speed and isolation. Each test SHALL create a fresh container. The `SoftDeletable` test suite uses `.serialized` trait and a dedicated container per test to avoid SwiftData context invalidation across concurrent tests.

## Verification

- `swift build` SHALL succeed with no errors or warnings on macOS 14+ with Xcode 16+.
- `swift test` SHALL run all tests using Swift Testing framework.
- `xcrun swift-format lint --strict --recursive Sources/ Tests/ Package.swift Demo/` SHALL pass with no errors.
- The package SHALL have zero external dependencies.
