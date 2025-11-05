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
                                               options: .firesOnRecordUpdate)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.title = "Session Logged"
        notificationInfo.alertBody = "A new session was just completed on your iPhone."
        notificationInfo.soundName = "default"
        notificationInfo.shouldBadge = true
        
        // This tells CloudKit to only send a notification when the 'CD_endTime' field changes.
        // This is key to only firing when a session is *completed*.
        notificationInfo.desiredKeys = ["CD_endTime"]
        
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
            } else {
                print("⚠️ Notification permission denied.")
            }
        }
    }
}
