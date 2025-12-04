//
//  SessionStore.swift
//  Uri Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import Foundation
import SwiftData
import Combine

class SessionStore: ObservableObject {
    @Published var currentSession: PeeSession?
    
    private let modelContext: ModelContext
    private let platformName: String
    
    init(modelContext: ModelContext, platformName: String = "Device") {
        self.modelContext = modelContext
        self.platformName = platformName
    }
    
    func startSession() {
        guard currentSession == nil else { return }
        
        // Create session with CURRENT device time
        let session = PeeSession()
        print("🔵 Session started at: \(session.startTime?.description ?? "unknown")")
    SyncMonitor.shared.logEvent("Session started on \(platformName)", type: .info)
        
        // Insert into local context FIRST
        modelContext.insert(session)
        currentSession = session
        
        // Save to local database immediately (CloudKit sync happens in background)
        do {
            SyncMonitor.shared.reportSyncStarted()
            try modelContext.save()
            print("✅ Session saved to LOCAL database (CloudKit will sync in background)")
            SyncMonitor.shared.reportSyncSuccess()
            SyncMonitor.shared.logEvent("Session saved locally on \(platformName)", type: .success)
        } catch {
            print("❌ Failed to save session locally: \(error)")
            SyncMonitor.shared.reportSyncError("Failed to save session: \(error.localizedDescription)")
        }
    }
    
    func endSession(feeling: SessionFeeling, symptoms: [Symptom] = [], notes: String = "") {
        guard let session = currentSession else { 
            print("⚠️ No current session to end")
            return 
        }
        
        print("🔵 Completing session: \(session.id?.uuidString ?? "unknown")")
        SyncMonitor.shared.logEvent("Completing session on \(platformName)", type: .info)
        
        // Session's endTime and duration were already set when user pressed Complete Session button
        // Just update the feeling, symptoms, and notes
        session.feeling = feeling
        session.symptoms = symptoms
        session.notes = notes
        
        print("⏱️  Start: \(session.startTime?.description ?? "unknown")")
        print("⏱️  End: \(session.endTime?.description ?? "unknown")")
        print("⏱️  Duration: \(session.duration ?? 0)s")
        
        // Save to LOCAL database IMMEDIATELY (CloudKit syncs in background)
        do {
            SyncMonitor.shared.reportSyncStarted()
            try modelContext.save()
            print("✅ Session saved to LOCAL database (CloudKit will sync in background)")
            SyncMonitor.shared.reportSyncSuccess()
            SyncMonitor.shared.logEvent("Session completed and saved on \(platformName) (Duration: \(Int(session.duration ?? 0))s)", type: .success)
        } catch {
            print("❌ Failed to save session: \(error)")
            SyncMonitor.shared.reportSyncError("Failed to save session: \(error.localizedDescription)")
        }
        
        // Clear current session
        currentSession = nil
        print("🔵 Current session cleared")
    }
    
    func cancelSession() {
        if let session = currentSession {
            modelContext.delete(session)
            try? modelContext.save()
            currentSession = nil
        }
    }
    
    func fetchSessions(from startDate: Date? = nil, to endDate: Date? = nil, limit: Int = 500) -> [PeeSession] {
        var descriptor = FetchDescriptor<PeeSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        // Add fetch limit to prevent memory issues
        descriptor.fetchLimit = limit
        
        if let startDate = startDate, let endDate = endDate {
            descriptor.predicate = #Predicate<PeeSession> { session in
                if let sessionStart = session.startTime {
                    sessionStart >= startDate && sessionStart <= endDate
                } else {
                    false
                }
            }
        }
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func deleteSession(_ session: PeeSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }
}
