//
//  Uri_TrackerApp.swift
//  Uri Tracker Watch App
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData

@main
struct Uri_Tracker_Watch_AppApp: App {
    
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
