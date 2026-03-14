# SwiftDataRecord

## Overview

SwiftDataRecord is a Swift Package Manager (SPM) library that brings Active Record-style ergonomics to Apple's SwiftData framework. It is inspired by [michalkonturek/ActiveRecord](https://github.com/michalkonturek/ActiveRecord), a lightweight Active Record implementation for Core Data written in Objective-C.

SwiftData already handles model definition (`@Model`), basic CRUD, and SwiftUI integration. SwiftDataRecord fills the gaps SwiftData leaves open:

1. **Static finder/query conveniences** — type-safe class-method style queries on any `PersistentModel` (e.g. `Trip.all(where:)`, `Trip.first(where:)`, `Trip.count(where:)`).
2. **JSON-based upsert** — create-or-update from `Decodable` dictionaries, matching on a configurable primary key, including nested relationship graphs.
3. **Batch operations** — `deleteAll()`, `deleteAll(where:)`, bulk upsert from JSON arrays.

## Tech Stack

- **Language:** Swift 6.0+
- **Frameworks:** SwiftData (iOS 17+ / macOS 14+ / tvOS 17+ / watchOS 10+)
- **Distribution:** Swift Package Manager (single target, no external dependencies)
- **Testing:** Swift Testing framework (`import Testing`)
- **Minimum tooling:** Xcode 16+

## Architecture Principles

- **Protocol-first design.** All functionality is delivered via protocol extensions on `PersistentModel`. No base classes, no inheritance hierarchies.
- **Context-explicit API.** Every query/mutation method requires a `ModelContext` parameter. No global singletons, no hidden shared state.
- **Composable, not monolithic.** The package exposes independent protocols that models can adopt selectively:
  - `Queryable` — static finders and predicates
  - `Upsertable` — JSON-based create-or-update
- **SwiftData-native.** Uses `#Predicate`, `FetchDescriptor`, `SortDescriptor`, and `ModelContext` throughout. Does not reach into Core Data internals.
- **Throwing by default.** All persistence operations propagate errors. No silent failures.

## Non-Goals

- Replacing `@Query` in SwiftUI views. This library targets imperative/service-layer code (view models, background tasks, sync engines), not SwiftUI's declarative layer.
- Core Data compatibility. This library is SwiftData-only.
- Background context management. The caller owns the `ModelContext` lifecycle.
- Networking or API client functionality.
