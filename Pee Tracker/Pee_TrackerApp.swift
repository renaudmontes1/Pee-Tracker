//
//  Pee_TrackerApp.swift
//  Pee Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData

@main
struct Pee_TrackerApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([PeeSession.self])
            
            // Configure CloudKit sync with explicit container identifier
            // This MUST match the container in both entitlements files
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.rens-corp.Pee-Pee-Tracker")
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            print("✅ iPhone: ModelContainer initialized with CloudKit sync")
            print("📦 Container: iCloud.rens-corp.Pee-Pee-Tracker")
        } catch {
            print("❌ Failed to initialize ModelContainer: \(error)")
            print("⚠️ If you see CloudKit errors, make sure:")
            print("   1. iCloud capability is enabled in Xcode")
            print("   2. You're signed in with an Apple ID")
            print("   3. The container exists in CloudKit Dashboard")
            
            // Fallback to local-only storage
            let schema = Schema([PeeSession.self])
            let fallbackConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
                print("⚠️ Using local storage only (no sync)")
            } catch {
                fatalError("Could not initialize ModelContainer: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
