import Foundation
import SwiftData
import active_record

// MARK: - Define Your Models

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

// MARK: - Setup

let container = try ModelContainer(
    for: Todo.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
)
let context = ModelContext(container)

// MARK: - Create Records

let task1 = Todo(uid: 1, title: "Buy groceries", priority: 2)
let task2 = Todo(uid: 2, title: "Write tests", priority: 1, completed: true)
let task3 = Todo(uid: 3, title: "Deploy app", priority: 3)

context.insert(task1)
context.insert(task2)
context.insert(task3)
try context.save()

// MARK: - Queryable: Fetch All

let allTodos = try Todo.all(in: context)
print("All tasks: \(allTodos.map(\.title))")
// ["Buy groceries", "Write tests", "Deploy app"]

// MARK: - Queryable: Filter with Predicate

let pending = try Todo.all(where: #Predicate { !$0.completed }, in: context)
print("Pending: \(pending.map(\.title))")
// ["Buy groceries", "Deploy app"]

// MARK: - Queryable: Sort

let byPriority = try Todo.all(
    where: nil,
    sort: SortDescriptor(\.priority, order: .reverse),
    in: context
)
print("By priority (desc): \(byPriority.map(\.title))")
// ["Deploy app", "Buy groceries", "Write tests"]

// MARK: - Queryable: Pagination

let page = try Todo.all(where: nil, sort: [], limit: 2, offset: 0, in: context)
print("First page (2 items): \(page.map(\.title))")

// MARK: - Queryable: First

if let first = try Todo.first(in: context) {
    print("First task: \(first.title)")
}

let highPriority = try Todo.first(
    where: #Predicate { $0.priority >= 3 },
    in: context
)
print("Highest priority task: \(highPriority?.title ?? "none")")
// "Deploy app"

// MARK: - Queryable: Count & Exists

let totalCount = try Todo.count(in: context)
print("Total tasks: \(totalCount)")
// 3

let completedCount = try Todo.count(
    where: #Predicate { $0.completed },
    in: context
)
print("Completed: \(completedCount)")
// 1

let hasTodos = try Todo.exists(in: context)
print("Has tasks: \(hasTodos)")
// true

// MARK: - Queryable: Aggregates

if let highest = try Todo.withMaxValue(for: \.priority, in: context) {
    print("Max priority: \(highest.title) (\(highest.priority))")
    // "Deploy app (3)"
}

if let lowest = try Todo.withMinValue(for: \.priority, in: context) {
    print("Min priority: \(lowest.title) (\(lowest.priority))")
    // "Write tests (1)"
}

// MARK: - Queryable: Sum, Average, Pluck

let totalPriority = try Todo.sum(for: \.priority, in: context)
print("Sum of priorities: \(totalPriority)")
// 6

let avgPriority = try Todo.average(for: \.priority, in: context)
print("Average priority: \(avgPriority ?? 0)")
// 2.0

let filteredSum = try Todo.sum(
    for: \.priority,
    where: #Predicate { !$0.completed },
    in: context
)
print("Sum of pending priorities: \(filteredSum)")
// 5

let titles = try Todo.pluck(\.title, in: context)
print("All titles: \(titles)")
// ["Buy groceries", "Write tests", "Deploy app"]

// MARK: - Queryable: Find or Create

let found = try Todo.firstOrCreate(
    where: #Predicate { $0.uid == 1 },
    in: context
) {
    Todo(uid: 1, title: "Should not be created", priority: 0)
}
print("Found existing: \(found.title)")
// "Buy groceries"

let created2 = try Todo.firstOrCreate(
    where: #Predicate { $0.uid == 99 },
    in: context
) {
    Todo(uid: 99, title: "Brand new task", priority: 2)
}
print("Created new: \(created2.title)")
// "Brand new task"

// firstOrInitialize does NOT insert into context
let initialized = try Todo.firstOrInitialize(
    where: #Predicate { $0.uid == 100 },
    in: context
) {
    Todo(uid: 100, title: "Not yet persisted", priority: 1)
}
print("Initialized (not persisted): \(initialized.title)")

// MARK: - Queryable: Update All

try Todo.updateAll(
    where: #Predicate { !$0.completed },
    in: context
) { $0.priority += 1 }

print("After updateAll, priorities: \(try Todo.pluck(\.priority, in: context).sorted())")

// MARK: - Queryable: Delete

try Todo.deleteAll(where: #Predicate { $0.completed }, in: context)
print("After deleting completed: \(try Todo.count(in: context)) tasks")
// 2

// MARK: - Upsertable: Create or Update from JSON

let json = """
    {"uid": 4, "title": "Review PR", "priority": 2, "completed": false}
    """.data(using: .utf8)!

let created = try Todo.createOrUpdate(from: json, in: context)
print("Created: \(created.title)")
// "Review PR"

// Update the same record (same uid)
let updateJson = """
    {"uid": 4, "title": "Review PR (approved)", "priority": 1, "completed": true}
    """.data(using: .utf8)!

let updated = try Todo.createOrUpdate(from: updateJson, in: context)
print("Updated: \(updated.title), completed: \(updated.completed)")
// "Review PR (approved)", completed: true

// MARK: - Upsertable: Create or Update from Dictionary

let dict: [String: Any] = [
    "uid": 5,
    "title": "Ship v1.0",
    "priority": 1,
    "completed": false,
]
let fromDict = try Todo.createOrUpdate(from: dict, in: context)
print("From dict: \(fromDict.title)")
// "Ship v1.0"

// MARK: - Upsertable: Batch Upsert

let batchJson = """
    [
        {"uid": 10, "title": "Task A", "priority": 1},
        {"uid": 11, "title": "Task B", "priority": 2},
        {"uid": 12, "title": "Task C", "priority": 3}
    ]
    """.data(using: .utf8)!

let batch = try Todo.createOrUpdate(fromArray: batchJson, in: context)
print("Batch created: \(batch.map(\.title))")
// ["Task A", "Task B", "Task C"]

// MARK: - Clean Up

try Todo.deleteAll(in: context)
print("After deleteAll: \(try Todo.count(in: context)) tasks")
// 0

// MARK: - SoftDeletable Demo

@Model
final class Post: SoftDeletable {
    var uid: Int
    var title: String
    var deletedAt: Date?

    init(uid: Int, title: String, deletedAt: Date? = nil) {
        self.uid = uid
        self.title = title
        self.deletedAt = deletedAt
    }
}

let postContainer = try ModelContainer(
    for: Post.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
)
let postContext = ModelContext(postContainer)

let post1 = Post(uid: 1, title: "Hello World")
let post2 = Post(uid: 2, title: "Swift Tips")
let post3 = Post(uid: 3, title: "Draft Post")
postContext.insert(post1)
postContext.insert(post2)
postContext.insert(post3)
try postContext.save()

print("\nPosts: \(try Post.count(in: postContext))")
// 3

// Soft delete
post3.softDelete()
try postContext.save()

print("After soft delete: \(try Post.count(in: postContext)) visible")
// 2

print("Including trashed: \(try Post.countWithTrashed(in: postContext))")
// 3

print("Only trashed: \(try Post.countOnlyTrashed(in: postContext))")
// 1

// Restore
post3.restore()
try postContext.save()
print("After restore: \(try Post.count(in: postContext)) visible")
// 3

// deleteAll soft-deletes by default
try Post.deleteAll(in: postContext)
print("After deleteAll: \(try Post.count(in: postContext)) visible, \(try Post.countWithTrashed(in: postContext)) total")
// 0 visible, 3 total

// destroyAll permanently removes
try Post.destroyAll(in: postContext)
try postContext.save()
print("After destroyAll: \(try Post.countWithTrashed(in: postContext)) total")
// 0
