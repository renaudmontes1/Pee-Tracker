//
//  ModelConfiguration.swift
//  Pee Tracker
//
//  Created by Admin on 10/27/25.
//

import Foundation
import SwiftData

extension ModelConfiguration {
    /// Shared configuration for iPhone and Watch to ensure CloudKit sync
    static var shared: ModelConfiguration {
        // Using explicit container name ensures both apps sync to same CloudKit database
        // Container ID format: iCloud.{bundle-id-base}
        // Both apps must use EXACTLY the same container name
        
        return ModelConfiguration(
            schema: Schema([PeeSession.self]),
            isStoredInMemoryOnly: false,
            groupContainer: .none,  // Each app has its own local storage
            cloudKitDatabase: .automatic  // Uses iCloud private database
        )
    }
}

// Note: For sync to work properly:
// 1. Both iPhone and Watch must use same AppleID/iCloud account
// 2. Both must have iCloud capability enabled in Xcode
// 3. Both must use same CloudKit container (automatic uses bundle ID)
// 4. Internet connection required for initial sync
