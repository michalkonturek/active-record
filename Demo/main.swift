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
