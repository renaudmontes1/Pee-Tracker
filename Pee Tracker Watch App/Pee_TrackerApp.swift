//
//  Pee_TrackerApp.swift
//  Pee Tracker Watch App
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData

@main
struct Pee_Tracker_Watch_AppApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([PeeSession.self])
            
            // Configure local-first storage with CloudKit sync
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,  // Store on device (local SQLite)
                cloudKitDatabase: .automatic  // Sync to CloudKit when available
            )
            
            // This configuration ensures:
            // 1. All data is FIRST saved to local SQLite database on Watch
            // 2. CloudKit sync happens in background (non-blocking)
            // 3. Start/stop times are captured locally with Watch time
            // 4. Works offline - syncs when paired iPhone is available
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            print("✅ Watch ModelContainer initialized with local-first storage")
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
