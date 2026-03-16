# active-record

[![Tests](https://github.com/michalkonturek/active-record/actions/workflows/tests.yml/badge.svg)](https://github.com/michalkonturek/active-record/actions/workflows/tests.yml)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20|%20macOS%2014%20|%20tvOS%2017%20|%20watchOS%2010-blue.svg)](https://developer.apple.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A lightweight Active Record implementation for SwiftData. Adds `Queryable`, `Upsertable`, `Timestampable`, `SoftDeletable`, and `Validatable` protocols that bring expressive finders, JSON-based upserts, managed timestamps, soft delete, and model validation to your `@Model` types.

Inspired by [ActiveRecord for Core Data](https://github.com/michalkonturek/ActiveRecord).

## Requirements

- Swift 6.0+
- iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/michalkonturek/active-record.git", from: "2.1.0"),
]
```

Then add `"ActiveRecord"` as a dependency of your target.

## Usage

### Define Your Model

Conform your `@Model` to `Queryable` for query methods, or to both `Queryable` and `Upsertable` for JSON upsert support:

```swift
import ActiveRecord
import SwiftData

@Model
final class Todo: Queryable, Upsertable {
    static var primaryKeyPath: KeyPath<Todo, Int> { \.uid }
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

**Fetch, filter, sort, and paginate:**

```swift
let tasks = try Todo.all(in: context)
let pending = try Todo.all(where: #Predicate { !$0.completed }, in: context)
let byPriority = try Todo.all(
    where: nil,
    sort: SortDescriptor(\.priority, order: .reverse),
    in: context
)
let page = try Todo.all(where: nil, sort: [], limit: 20, offset: 0, in: context)
```

**First, count, and exists:**

```swift
let first = try Todo.first(in: context)
let urgent = try Todo.first(where: #Predicate { $0.priority >= 3 }, in: context)
let count = try Todo.count(in: context)
let hasCompleted = try Todo.exists(where: #Predicate { $0.completed }, in: context)
```

**Aggregates:**

```swift
let highest = try Todo.withMaxValue(for: \.priority, in: context)
let lowest = try Todo.withMinValue(for: \.priority, in: context)
let totalPriority = try Todo.sum(for: \.priority, in: context)
let avgPriority = try Todo.average(for: \.priority, in: context)
let titles = try Todo.pluck(\.title, in: context)
```

**Find or create:**

```swift
let todo = try Todo.firstOrCreate(
    where: #Predicate { $0.uid == 42 },
    in: context
) {
    Todo(uid: 42, title: "New task", priority: 1)
}
```

**Bulk update and delete:**

```swift
try Todo.updateAll(where: #Predicate { $0.priority < 3 }, in: context) {
    $0.priority += 1
}
try Todo.deleteAll(where: #Predicate { $0.completed }, in: context)
try Todo.deleteAll(in: context)
```

### Timestampable

Add managed `createdAt` / `updatedAt` timestamps to any model:

```swift
@Model
final class Todo: Queryable, Upsertable, Timestampable {
    // ... existing properties ...
    var createdAt: Date
    var updatedAt: Date
}

// Manual timestamp management
todo.stampCreated()  // sets both createdAt and updatedAt
todo.touch()         // sets updatedAt only

// Auto-stamping: createOrUpdate() and firstOrCreate() automatically
// call stampCreated() on Timestampable models.
```

### SoftDeletable

Mark records as deleted without removing them from the database:

```swift
@Model
final class Post: SoftDeletable {
    var uid: Int
    var title: String
    var deletedAt: Date?  // required by SoftDeletable
}
```

**Soft delete and restore:**

```swift
post.softDelete()  // sets deletedAt, keeps record in DB
post.restore()     // clears deletedAt
```

**Standard queries auto-exclude soft-deleted records:**

```swift
let posts = try Post.all(in: context)    // only non-deleted
let count = try Post.count(in: context)  // only non-deleted
try Post.deleteAll(in: context)          // soft-deletes by default
```

**Escape hatches and permanent deletion:**

```swift
let all = try Post.allWithTrashed(in: context)     // includes soft-deleted
let trashed = try Post.allOnlyTrashed(in: context) // only soft-deleted
try Post.destroyAll(in: context)                    // permanent hard delete
```

### Validatable

Add runtime validation to any model — write rules in plain Swift:

```swift
@Model
final class Item: Queryable, Validatable {
    var name: String
    var price: Int

    func validate() throws {
        var failures: [ValidationError.FieldError] = []
        if name.isEmpty {
            failures.append(.init(field: "name", message: "can't be empty"))
        }
        if price < 0 {
            failures.append(.init(field: "price", message: "must be non-negative"))
        }
        if !failures.isEmpty {
            throw ValidationError(failures: failures)
        }
    }
}
```

**Check validity:**

```swift
item.isValid  // true or false (no throw)
try item.validate()  // throws ValidationError with field details
```

**Auto-validation:** `createOrUpdate()` and `firstOrCreate()` automatically validate models conforming to `Validatable`. Invalid models are rejected before persistence.

### Upsertable

Create or update records from JSON. Matching is based on the primary key — if a record with the same key exists, it is replaced.

**From JSON data:**

```swift
let json = """
    {"uid": 1, "title": "Review PR", "priority": 2, "completed": false}
    """.data(using: .utf8)!
let task = try Todo.createOrUpdate(from: json, in: context)
```

**From a dictionary:**

```swift
let task = try Todo.createOrUpdate(from: [
    "uid": 1,
    "title": "Review PR",
    "priority": 2,
    "completed": false,
], in: context)
```

**Batch upsert from JSON array:**

```swift
let batchJson = """
    [
        {"uid": 10, "title": "Task A", "priority": 1},
        {"uid": 11, "title": "Task B", "priority": 2}
    ]
    """.data(using: .utf8)!
let tasks = try Todo.createOrUpdate(fromArray: batchJson, in: context)
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
| `sum(for:in:)` | Sum of a numeric key path |
| `sum(for:where:in:)` | Filtered sum |
| `average(for:in:)` | Average of an integer key path (returns `Double?`) |
| `average(for:where:in:)` | Filtered average |
| `pluck(_:in:)` | Extract single field as `[V]` |
| `pluck(_:where:in:)` | Filtered pluck |
| `firstOrCreate(where:in:create:)` | Find or create and insert |
| `firstOrInitialize(where:in:create:)` | Find or create without inserting |
| `updateAll(where:in:apply:)` | Bulk update with mutation closure |
| `deleteAll(in:)` | Delete all records |
| `deleteAll(where:in:)` | Delete matching records |

### SoftDeletable

| Method | Description |
|--------|-------------|
| `softDelete()` | Sets `deletedAt` to now (keeps record) |
| `restore()` | Clears `deletedAt` |
| `all(in:)` | Auto-excludes soft-deleted records |
| `first(in:)` | Auto-excludes soft-deleted records |
| `count(in:)` | Auto-excludes soft-deleted records |
| `exists(in:)` | Auto-excludes soft-deleted records |
| `deleteAll(in:)` | Soft-deletes instead of removing |
| `destroyAll(in:)` | Permanently deletes all records |
| `destroyAll(where:in:)` | Permanently deletes matching records |
| `allWithTrashed(in:)` | All records including soft-deleted |
| `countWithTrashed(in:)` | Count including soft-deleted |
| `existsWithTrashed(in:)` | Exists including soft-deleted |
| `allOnlyTrashed(in:)` | Only soft-deleted records |
| `countOnlyTrashed(in:)` | Count of soft-deleted records |

### Upsertable

| Method | Description |
|--------|-------------|
| `createOrUpdate(from:in:)` | Upsert from JSON `Data` |
| `createOrUpdate(from:in:)` | Upsert from `[String: Any]` |
| `createOrUpdate(fromArray:in:)` | Batch upsert from JSON array |

### Timestampable

| Method | Description |
|--------|-------------|
| `touch()` | Sets `updatedAt` to now |
| `stampCreated()` | Sets both `createdAt` and `updatedAt` to now |

Auto-stamps on `createOrUpdate()` and `firstOrCreate()` when the model conforms to `Timestampable`.

### Validatable

| Method | Description |
|--------|-------------|
| `validate()` | Throws `ValidationError` if model is invalid |
| `isValid` | Returns `true` if `validate()` does not throw |

Auto-validates on `createOrUpdate()` and `firstOrCreate()` when the model conforms to `Validatable`.

## License

MIT
