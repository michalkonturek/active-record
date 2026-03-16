import Foundation
import SwiftData

@MainActor
func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: Student.self, Course.self, Module.self, Article.self, Item.self,
        configurations: config
    )
}
