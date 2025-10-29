//
//  SessionStore.swift
//  Pee Tracker Watch App
//
//  Created by Admin on 10/27/25.
//

import Foundation
import SwiftData
import Combine

class SessionStore: ObservableObject {
    @Published var currentSession: PeeSession?
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func startSession() {
        guard currentSession == nil else { return }
        
        // Create session with CURRENT device time
        let session = PeeSession()
        print("🔵 Session started at: \(session.startTime)")
        
        // Insert into local context FIRST
        modelContext.insert(session)
        currentSession = session
        
        // Save to local database immediately (CloudKit sync happens in background)
        do {
            try modelContext.save()
            print("✅ Session saved to LOCAL database (CloudKit will sync in background)")
        } catch {
            print("❌ Failed to save session locally: \(error)")
        }
    }
    
    func endSession(feeling: SessionFeeling, symptoms: [Symptom] = [], notes: String = "") {
        guard let session = currentSession else { 
            print("⚠️ No current session to end")
            return 
        }
        
        print("🔵 Ending session: \(session.id)")
        
        // Update session properties with LOCAL device time
        session.endSession()  // Sets endTime to Date() - current device time
        session.feeling = feeling
        session.symptoms = symptoms
        session.notes = notes
        
        print("⏱️  Start: \(session.startTime)")
        print("⏱️  End: \(session.endTime!)")
        print("⏱️  Duration: \(session.duration)s")
        
        // Save to LOCAL database IMMEDIATELY (CloudKit syncs in background)
        do {
            try modelContext.save()
            print("✅ Session saved to LOCAL database (CloudKit will sync in background)")
        } catch {
            print("❌ Failed to save session: \(error)")
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
    
    func fetchSessions(from startDate: Date? = nil, to endDate: Date? = nil) -> [PeeSession] {
        var descriptor = FetchDescriptor<PeeSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        if let startDate = startDate, let endDate = endDate {
            descriptor.predicate = #Predicate<PeeSession> { session in
                session.startTime >= startDate && session.startTime <= endDate
            }
        }
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func deleteSession(_ session: PeeSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }
}
