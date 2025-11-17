//
//  SubscriptionManager.swift
//  Pee Tracker
//
//  Created by GitHub Copilot on 10/29/25.
//

import Foundation
import CloudKit
import UserNotifications
import CoreData

class SubscriptionManager {
    
    static let shared = SubscriptionManager()
    // MUST use the same container as SwiftData ModelConfiguration
    private let database = CKContainer(identifier: "iCloud.rens-corp.Pee-Pee-Tracker").privateCloudDatabase
    
    // Track when user last viewed history
    private let lastViewedKey = "lastViewedHistoryDate"
    private let badgeCountKey = "appBadgeCount"
    
    private init() {}
    
    func registerSubscription() {
        // Check if subscription already exists
        database.fetchAllSubscriptions { subscriptions, error in
            if let error = error {
                print("❌ Error fetching subscriptions: \(error.localizedDescription)")
                return
            }
            
            let subscriptionID = "session-completed-subscription"
            
            if let subscriptions = subscriptions, subscriptions.contains(where: { $0.subscriptionID == subscriptionID }) {
                print("✅ Subscription already exists.")
                return
            }
            
            // If not, create a new one
            self.createSubscription(subscriptionID: subscriptionID)
        }
    }
    
    private func createSubscription(subscriptionID: String) {
        // The record type for a SwiftData model is "CD_" + your model's name.
        let subscription = CKQuerySubscription(recordType: "CD_PeeSession",
                                               predicate: NSPredicate(value: true),
                                               subscriptionID: subscriptionID,
                                               options: .firesOnRecordCreation)  // Changed to firesOnRecordCreation to catch new sessions
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New session logged on your Watch"
        notificationInfo.soundName = "default"
        
        // Category to support incrementing badge
        notificationInfo.category = "NEW_SESSION"
        
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription) { returnedSubscription, returnedError in
            if let returnedError = returnedError {
                print("❌ Failed to save subscription: \(returnedError.localizedDescription)")
            } else {
                print("✅ Successfully created subscription!")
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
                return
            }
            if granted {
                print("✅ Notification permission granted.")
                // Register notification categories
                self.setupNotificationCategories()
            } else {
                print("⚠️ Notification permission denied.")
            }
        }
    }
    
    private func setupNotificationCategories() {
        let category = UNNotificationCategory(
            identifier: "NEW_SESSION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // MARK: - Badge Management
    
    func updateBadgeForNewSession() {
        #if os(iOS)
        let currentCount = UserDefaults.standard.integer(forKey: badgeCountKey)
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: badgeCountKey)
        
        UNUserNotificationCenter.current().setBadgeCount(newCount) { error in
            if let error = error {
                print("❌ Failed to increment badge: \(error.localizedDescription)")
            } else {
                print("✅ Badge incremented to \(newCount) for new session")
            }
        }
        #endif
    }
    
    func clearBadge() {
        #if os(iOS)
        UserDefaults.standard.set(0, forKey: badgeCountKey)
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("❌ Failed to clear badge: \(error.localizedDescription)")
            } else {
                print("✅ Badge cleared")
            }
        }
        #endif
    }
    
    func markHistoryViewed() {
        UserDefaults.standard.set(Date(), forKey: lastViewedKey)
        clearBadge()
    }
}
