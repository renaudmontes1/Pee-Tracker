//
//  PeeSession.swift
//  Pee Tracker Watch App
//
//  Created by Admin on 10/27/25.
//

import Foundation
import SwiftData

@Model
final class PeeSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var feeling: SessionFeeling
    var symptoms: [Symptom]
    var notes: String
    
    var isActive: Bool {
        endTime == nil
    }
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: TimeInterval = 0,
        feeling: SessionFeeling = .positive,
        symptoms: [Symptom] = [],
        notes: String = ""
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.feeling = feeling
        self.symptoms = symptoms
        self.notes = notes
    }
    
    func endSession() {
        guard endTime == nil else { 
            print("⚠️ Session already ended at \(endTime!)")
            return 
        }
        let now = Date()
        endTime = now
        duration = now.timeIntervalSince(startTime)
        print("✅ Session ended. Duration: \(duration)s")
    }
}

enum SessionFeeling: String, Codable, CaseIterable {
    case positive = "Positive"
    case negative = "Negative"
    
    var emoji: String {
        switch self {
        case .positive: return "✅"
        case .negative: return "❌"
        }
    }
}

enum Symptom: String, Codable, CaseIterable {
    case notFullyEmpty = "Not fully empty"
    case dripping = "Dripping"
    case pain = "Pain"
    case blood = "Blood"
    
    var icon: String {
        switch self {
        case .notFullyEmpty: return "🚽"
        case .dripping: return "💧"
        case .pain: return "⚡️"
        case .blood: return "🩸"
        }
    }
}
