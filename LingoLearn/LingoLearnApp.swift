//
//  LingoLearnApp.swift
//  LingoLearn
//
//  Created by charles qin on 12/19/25.
//

import SwiftUI
import SwiftData

@main
struct LingoLearnApp: App {
    private let container: ModelContainer = {
        let schema = Schema([
            Word.self,
            PracticeAttempt.self,
            DailyStats.self,
            Achievement.self,
            UserSettings.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
