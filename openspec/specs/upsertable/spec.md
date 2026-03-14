# Upsertable — JSON-Based Create or Update Protocol

## Purpose

Provide Active Record-style `createOrUpdate` from JSON dictionaries, matching the original library's ability to hydrate full object graphs — including nested relationships — from a single dictionary.

## Inspiration

Maps to ActiveRecord's JSON serialization feature:

```objc
// Original ActiveRecord (Obj-C)
id student = [Student createOrUpdateWithData:jsonDictionary];
```

The original library would:
1. Look up an existing object by primary key (`uid`).
2. If found, update its attributes. If not, create a new one.
3. Recursively handle nested dictionaries as to-one relationships.
4. Recursively handle nested arrays as to-many relationships.

## Specification

### Protocol Definition

The system SHALL define an `Upsertable` protocol constrained to `PersistentModel & Decodable`.

```swift
protocol Upsertable: PersistentModel, Decodable {
    associatedtype PrimaryKey: Equatable
    static var primaryKeyPath: KeyPath<Self, PrimaryKey> { get }
    static var primaryCodingKey: String { get }
}
```

- `primaryKeyPath` — the Swift key path used to look up existing records (e.g. `\.uid`).
- `primaryCodingKey` — the string key in the JSON dictionary that holds the primary key value (e.g. `"uid"`). Defaults to the last component of `primaryKeyPath` when possible. Models MAY override this for key name mismatches.

### Core Methods

#### Single Upsert

```swift
static func createOrUpdate(
    from data: Data,
    using decoder: JSONDecoder = JSONDecoder(),
    in context: ModelContext
) throws -> Self
```

The system SHALL:
1. Decode the primary key value from `data` using `primaryCodingKey`.
2. Query the context for an existing object where `primaryKeyPath == decodedKey`.
3. If found — update the existing object's properties from the decoded values.
4. If not found — decode a new instance and insert it into the context.
5. Return the created or updated object.

The system SHALL NOT auto-save after upsert. The caller decides when to save.

#### Batch Upsert

```swift
static func createOrUpdate(
    from data: Data,
    using decoder: JSONDecoder = JSONDecoder(),
    in context: ModelContext
) throws -> [Self]
```

Accepts a JSON array. SHALL apply the single upsert logic to each element. SHALL return all created/updated objects.

#### Dictionary-Based Upsert

```swift
static func createOrUpdate(
    from dictionary: [String: Any],
    in context: ModelContext
) throws -> Self
```

Convenience overload that serializes the dictionary to JSON `Data` and delegates to the `Data`-based method.

### Relationship Handling

The original ActiveRecord automatically handled nested relationships:

```json
{
    "uid": 0,
    "firstName": "Jaclyn",
    "course": { "uid": 1, "name": "Software Engineering" },
    "modules": [
        { "uid": 0, "name": "Module 0" },
        { "uid": 1, "name": "Module 1" }
    ]
}
```

SwiftData handles relationship decoding through standard `Decodable` conformance when models implement `init(from:)`. The system SHALL document that:

- For automatic nested relationship upsert, related models MUST also conform to `Upsertable` and `Decodable`.
- The `init(from decoder:)` implementation on the model is responsible for decoding nested objects.
- The upsert logic applies only at the top level. Nested relationship upsert (find-or-create for related objects) is a model responsibility in the `Decodable` implementation. The spec SHALL provide a documented pattern/recipe for this in the package's README.

### CodingKey Flexibility

The system SHALL support custom `CodingKeys` through standard Swift `Decodable` patterns (e.g. `snake_case` to `camelCase` via `JSONDecoder.keyDecodingStrategy` or custom `CodingKeys` enum).

### Timestampable Integration

When a model conforms to both `Upsertable` and `Timestampable`, the `createOrUpdate(from:in:)` and `createOrUpdate(fromArray:in:)` methods SHALL call `stampCreated()` on each newly inserted model. This SHALL be implemented via a conditional conformance check after insertion. Non-Timestampable models SHALL be unaffected.

### Design Constraints

- All methods SHALL accept `ModelContext` as an explicit parameter.
- All methods SHALL be `throws`.
- The protocol SHALL NOT require models to subclass anything.
- The protocol SHALL NOT use reflection or Mirror. Decoding relies on Swift's `Decodable` machinery.
- The `PrimaryKey` associated type SHALL be constrained to `Equatable` to enable lookup queries. Common types: `Int`, `String`, `UUID`.

### Edge Cases

- Upserting with a primary key that matches an existing object SHALL update all decoded properties, not just non-nil ones (full replacement semantics, matching the original ActiveRecord behavior).
- Upserting a JSON array with duplicate primary keys SHALL process them in order; the last occurrence wins.
- Upserting with a JSON object missing the primary key field SHALL throw a descriptive error.
- Decoding failures (type mismatch, missing required fields) SHALL propagate the `DecodingError` to the caller.
- Batch upsert with an empty array SHALL return an empty array (no error).

## Verification

- Unit tests SHALL verify create path (object does not exist → new object inserted).
- Unit tests SHALL verify update path (object with matching key exists → properties updated).
- Unit tests SHALL verify batch upsert with mix of new and existing objects.
- Unit tests SHALL verify that duplicate keys in batch are handled (last wins).
- Unit tests SHALL verify error on missing primary key.
- Unit tests SHALL verify custom `CodingKeys` / `keyDecodingStrategy` work correctly.
- Unit tests SHALL verify that upsert does NOT auto-save (object is in context but context has unsaved changes).
- Tests SHALL use an in-memory `ModelContainer` for isolation.
