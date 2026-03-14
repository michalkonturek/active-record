# Package Structure

## Purpose

Define the Swift Package Manager layout, targets, and module organization for SwiftDataRecord.

## Specification

### Package Name

`SwiftDataRecord`

### Repository Layout

```
SwiftDataRecord/
├── Package.swift
├── README.md
├── LICENSE                          # MIT (matching original ActiveRecord)
├── openspec/
│   ├── project.md
│   └── specs/
│       ├── queryable/
│       │   └── spec.md
│       ├── upsertable/
│       │   └── spec.md
│       └── package-structure/
│           └── spec.md
├── Sources/
│   └── SwiftDataRecord/
│       ├── Queryable.swift          # Queryable protocol + extension
│       ├── Upsertable.swift         # Upsertable protocol + extension
│       └── Errors.swift             # SwiftDataRecordError enum
└── Tests/
    └── SwiftDataRecordTests/
        ├── Models/
        │   ├── Student.swift        # Test model: basic entity
        │   ├── Course.swift         # Test model: to-one relationship target
        │   └── Module.swift         # Test model: to-many relationship target
        ├── Helpers/
        │   └── TestContainer.swift  # In-memory ModelContainer factory
        ├── QueryableTests.swift
        └── UpsertableTests.swift
```

### Package.swift

```swift
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwiftDataRecord",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "SwiftDataRecord",
            targets: ["SwiftDataRecord"]
        )
    ],
    targets: [
        .target(
            name: "SwiftDataRecord"
        ),
        .testTarget(
            name: "SwiftDataRecordTests",
            dependencies: ["SwiftDataRecord"]
        )
    ]
)
```

### Design Decisions

- **Single target.** No sub-modules. The library is small enough that splitting `Queryable` and `Upsertable` into separate targets adds complexity without benefit. Users import one module: `import SwiftDataRecord`.
- **Zero external dependencies.** Only system frameworks: `SwiftData` and `Foundation`.
- **Swift 6.0 tools version.** Required for strict concurrency checking and latest SwiftData APIs.
- **Platform minimums.** iOS 17 / macOS 14 — the minimum for SwiftData availability.

### Error Type

The system SHALL define a single error enum:

```swift
public enum SwiftDataRecordError: Error, LocalizedError {
    case missingPrimaryKey(type: String, key: String)
    case decodingFailed(type: String, underlying: Error)
}
```

- `missingPrimaryKey` — thrown when JSON data lacks the expected primary key field during upsert.
- `decodingFailed` — wraps `DecodingError` with the model type name for better diagnostics.

### Test Models

Test models SHALL mirror the original ActiveRecord example domain:

- **Student** — has `uid: Int`, `firstName: String`, `lastName: String`, `age: Int`. Has a to-one relationship to `Course` and a to-many relationship to `[Module]`.
- **Course** — has `uid: Int`, `name: String`.
- **Module** — has `uid: Int`, `name: String`.

All test models SHALL conform to both `Queryable` and `Upsertable`.

### Test Container Helper

```swift
@MainActor
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: Student.self, Course.self, Module.self,
        configurations: config
    )
}
```

All tests SHALL use in-memory containers for speed and isolation. Each test SHALL create a fresh container.

## Verification

- `swift build` SHALL succeed with no errors or warnings on macOS 14+ with Xcode 16+.
- `swift test` SHALL run all tests using Swift Testing framework.
- The package SHALL have zero external dependencies verified by inspecting `Package.resolved` (should not exist or be empty).
