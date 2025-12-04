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
    
    init() {
        // Request permission for notifications
        SubscriptionManager.shared.requestNotificationPermission()
        // Register the subscription to listen for changes
        SubscriptionManager.shared.registerSubscription()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(ModelContainer.shared)
    }
}
