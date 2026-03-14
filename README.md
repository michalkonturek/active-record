# active-record

[![Tests](https://github.com/michalkonturek/active-record/actions/workflows/tests.yml/badge.svg)](https://github.com/michalkonturek/active-record/actions/workflows/tests.yml)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20|%20macOS%2014%20|%20tvOS%2017%20|%20watchOS%2010-blue.svg)](https://developer.apple.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A lightweight Active Record implementation for SwiftData. Adds `Queryable` and `Upsertable` protocols that bring expressive, context-explicit finders and JSON-based upserts to your `@Model` types.

Inspired by [ActiveRecord for Core Data](https://github.com/michalkonturek/ActiveRecord).

## Requirements

- Swift 6.0+
- iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/michalkonturek/active-record.git", from: "1.0.0"),
]
```

Then add `"active-record"` as a dependency of your target.

## Usage

### Define Your Model

Conform your `@Model` to `Queryable` for query methods, or to both `Queryable` and `Upsertable` for JSON upsert support:

```swift
import SwiftData
import active_record

@Model
final class Task: Queryable, Upsertable {
    static var primaryKeyPath: KeyPath<Task, Int> { \.uid }
    static var primaryCodingKey: String { "uid" }

    var uid: Int
    var title: String
    var priority: Int
    var completed: Bool

    init(uid: Int, title: String, priority: Int, completed: Bool = false) {
        self.uid = uid
        self.title = title
        self.priority = priority
        self.completed = completed
    }

    enum CodingKeys: String, CodingKey {
        case uid, title, priority, completed
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decode(Int.self, forKey: .uid)
        title = try container.decode(String.self, forKey: .title)
        priority = try container.decode(Int.self, forKey: .priority)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
    }
}
```

### Queryable

Every method takes a `ModelContext` explicitly — no singletons, no ambient state.

```swift
// Fetch all
let tasks = try Task.all(in: context)

// Filter with predicates
let pending = try Task.all(where: #Predicate { !$0.completed }, in: context)

// Sort
let byPriority = try Task.all(
    where: nil,
    sort: SortDescriptor(\.priority, order: .reverse),
    in: context
)

// Pagination
let page = try Task.all(where: nil, sort: [], limit: 20, offset: 0, in: context)

// First
let first = try Task.first(in: context)
let urgent = try Task.first(where: #Predicate { $0.priority >= 3 }, in: context)

// Count & exists
let count = try Task.count(in: context)
let hasCompleted = try Task.exists(where: #Predicate { $0.completed }, in: context)

// Aggregates
let highest = try Task.withMaxValue(for: \.priority, in: context)
let lowest = try Task.withMinValue(for: \.priority, in: context)

// Delete
try Task.deleteAll(where: #Predicate { $0.completed }, in: context)
try Task.deleteAll(in: context)
```

### Upsertable

Create or update records from JSON. Matching is based on the primary key — if a record with the same key exists, it is replaced.

```swift
// From JSON data
let json = """
    {"uid": 1, "title": "Review PR", "priority": 2, "completed": false}
    """.data(using: .utf8)!
let task = try Task.createOrUpdate(from: json, in: context)

// From a dictionary
let task = try Task.createOrUpdate(from: [
    "uid": 1,
    "title": "Review PR",
    "priority": 2,
    "completed": false,
], in: context)

// Batch upsert from JSON array
let batchJson = """
    [
        {"uid": 10, "title": "Task A", "priority": 1},
        {"uid": 11, "title": "Task B", "priority": 2}
    ]
    """.data(using: .utf8)!
let tasks = try Task.createOrUpdate(fromArray: batchJson, in: context)
```

## API Reference

### Queryable

| Method | Description |
|--------|-------------|
| `all(in:)` | Fetch all records |
| `all(where:in:)` | Fetch with predicate |
| `all(where:sort:in:)` | Fetch with predicate and sort |
| `all(where:sort:limit:offset:in:)` | Fetch with pagination |
| `first(in:)` | First record or `nil` |
| `first(where:in:)` | First matching record |
| `count(in:)` | Total record count |
| `count(where:in:)` | Filtered count |
| `exists(in:)` | Any records exist? |
| `exists(where:in:)` | Any matching records? |
| `withMaxValue(for:in:)` | Record with max value for key path |
| `withMinValue(for:in:)` | Record with min value for key path |
| `deleteAll(in:)` | Delete all records |
| `deleteAll(where:in:)` | Delete matching records |

### Upsertable

| Method | Description |
|--------|-------------|
| `createOrUpdate(from:in:)` | Upsert from JSON `Data` |
| `createOrUpdate(from:in:)` | Upsert from `[String: Any]` |
| `createOrUpdate(fromArray:in:)` | Batch upsert from JSON array |

## License

MIT
