//
//  PeeSession.swift
//  Uri Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import Foundation
import SwiftData

@Model
final class PeeSession {
    // All properties must be optional for CloudKit compatibility
    var id: UUID?
    var startTime: Date?
    var endTime: Date?
    var duration: TimeInterval?
    var feeling: SessionFeeling?
    var symptoms: [Symptom]?
    var notes: String?
    
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
        guard let start = startTime else {
            print("⚠️ Cannot end session: missing start time")
            return
        }
        let now = Date()
        endTime = now
        duration = now.timeIntervalSince(start)
        print("✅ Session ended. Duration: \(duration ?? 0)s")
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
    case pain = "Pain/Discomfort"
    case burning = "Burning sensation"
    case hesitancy = "Difficulty starting"
    case weakStream = "Weak stream"
    case incomplete = "Incomplete emptying"
    case urgency = "Frequent urges"
    case blood = "Blood present"
    
    // Custom decoder to handle legacy symptom names from CloudKit
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Map legacy symptom names to new ones
        switch rawValue {
        // Legacy mappings (v1.0)
        case "Not fully empty":
            self = .incomplete
        case "Dripping":
            self = .weakStream
        case "Pain":
            self = .pain
        case "Blood":
            self = .blood
            
        // v1.1 symptom names
        case "Pain/Discomfort":
            self = .pain
        case "Burning sensation":
            self = .burning
        case "Difficulty starting":
            self = .hesitancy
        case "Weak stream/Dripping":
            self = .weakStream
        case "Incomplete emptying":
            self = .incomplete
        case "Frequent urges":
            self = .urgency
        case "Blood present":
            self = .blood
            
        // v1.2 symptom names (current)
        case "Weak stream":
            self = .weakStream
            
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot initialize Symptom from unknown value: \(rawValue)"
                )
            )
        }
    }
    
    var icon: String {
        switch self {
        case .pain: return "⚡️"
        case .burning: return "🔥"
        case .hesitancy: return "⏸️"
        case .weakStream: return "💧"
        case .incomplete: return "🚽"
        case .urgency: return "⏰"
        case .blood: return "🩸"
        }
    }
    
    var description: String {
        switch self {
        case .pain:
            return "Any pain or discomfort during urination"
        case .burning:
            return "Burning or stinging sensation while urinating"
        case .hesitancy:
            return "Trouble initiating urine flow"
        case .weakStream:
            return "Weak or slow urine stream"
        case .incomplete:
            return "Feeling that bladder isn't fully empty"
        case .urgency:
            return "Sudden, urgent need to urinate"
        case .blood:
            return "Visible blood in urine (hematuria)"
        }
    }
}
