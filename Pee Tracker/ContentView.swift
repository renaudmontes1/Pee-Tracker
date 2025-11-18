//
//  ContentView.swift
//  Pee Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<PeeSession> { session in
            session.endTime != nil
        },
        sort: \PeeSession.startTime,
        order: .reverse
    ) private var sessions: [PeeSession]
    @State private var store: SessionStore?
    @State private var lastSessionCount = 0
    
    // Limit data for performance - only show recent sessions
    var recentSessions: [PeeSession] {
        Array(sessions.prefix(200))
    }
    
    var body: some View {
        TabView {
            // Logging Tab
            if let store = store {
                LoggingView(store: store)
                    .tabItem {
                        Label("Log", systemImage: "drop.fill")
                    }
            }
            
            // History Tab
            HistoryView(sessions: recentSessions)
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
            
            // Insights Tab
            InsightsView(sessions: recentSessions)
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            // Settings Tab
            SettingsView(sessions: sessions)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .onAppear {
            // Initialize store lazily to avoid init-time memory spike
            if store == nil {
                store = SessionStore(modelContext: modelContext, platformName: "iPhone")
            }
            lastSessionCount = sessions.count
        }
        .onChange(of: sessions.count) { oldCount, newCount in
            // If sessions increased, update badge
            if newCount > lastSessionCount {
                let newSessions = newCount - lastSessionCount
                updateBadge(increment: newSessions)
            }
            lastSessionCount = newCount
        }
    }
    
    private func updateBadge(increment: Int) {
        let badgeCountKey = "appBadgeCount"
        let currentBadge = UserDefaults.standard.integer(forKey: badgeCountKey)
        let newBadge = currentBadge + increment
        UserDefaults.standard.set(newBadge, forKey: badgeCountKey)
        
        UNUserNotificationCenter.current().setBadgeCount(newBadge) { error in
            if let error = error {
                print("❌ Failed to update badge: \(error.localizedDescription)")
            } else {
                print("✅ Badge updated: +\(increment) = \(newBadge)")
            }
        }
    }
}

// Extension to share ModelContainer
extension ModelContainer {
    static var shared: ModelContainer = {
        let schema = Schema([PeeSession.self])
        
        // MUST use same container as Watch app
        let containerIdentifier = "iCloud.rens-corp.Pee-Pee-Tracker"
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(containerIdentifier)
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ iPhone: Shared ModelContainer initialized with CloudKit sync")
            print("📦 Container: \(containerIdentifier)")
            return container
        } catch {
            print("❌ iPhone: Failed to create shared ModelContainer: \(error)")
            print("⚠️ CloudKit sync will NOT work. Check:")
            print("   1. iCloud capability enabled in Xcode")
            print("   2. Signed in with Apple ID")
            print("   3. Container '\(containerIdentifier)' exists")
            
            // Fallback to local-only
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                let container = try ModelContainer(for: schema, configurations: [fallbackConfig])
                print("⚠️ iPhone: Using local storage only (no sync)")
                return container
            } catch {
                fatalError("iPhone: Could not create ModelContainer: \(error)")
            }
        }
    }()
}

#Preview {
    ContentView()
        .modelContainer(ModelContainer.shared)
}

