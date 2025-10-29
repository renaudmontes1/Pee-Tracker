//
//  AnalyticsEngine.swift
//  Pee Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import Foundation

class AnalyticsEngine {
    
    // MARK: - Basic Statistics
    
    static func averageSessionsPerDay(sessions: [PeeSession], in dateRange: DateRange) -> Double {
        let completedSessions = sessions.filter { $0.endTime != nil }
        let daysInRange = dateRange.numberOfDays
        
        guard daysInRange > 0 else { return 0 }
        return Double(completedSessions.count) / Double(daysInRange)
    }
    
    static func totalSessions(sessions: [PeeSession], in dateRange: DateRange) -> Int {
        sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return dateRange.contains(endTime)
        }.count
    }
    
    static func averageDuration(sessions: [PeeSession]) -> TimeInterval {
        let completedSessions = sessions.filter { $0.endTime != nil }
        guard !completedSessions.isEmpty else { return 0 }
        
        let totalDuration = completedSessions.reduce(0.0) { $0 + $1.duration }
        return totalDuration / Double(completedSessions.count)
    }
    
    // MARK: - Symptom Analysis
    
    static func mostCommonSymptoms(sessions: [PeeSession], limit: Int = 3) -> [(Symptom, Int)] {
        var symptomCounts: [Symptom: Int] = [:]
        
        sessions.forEach { session in
            session.symptoms.forEach { symptom in
                symptomCounts[symptom, default: 0] += 1
            }
        }
        
        return symptomCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }
    
    static func symptomFrequency(sessions: [PeeSession]) -> [Symptom: Double] {
        let completedSessions = sessions.filter { $0.endTime != nil }
        guard !completedSessions.isEmpty else { return [:] }
        
        var symptomCounts: [Symptom: Int] = [:]
        
        completedSessions.forEach { session in
            session.symptoms.forEach { symptom in
                symptomCounts[symptom, default: 0] += 1
            }
        }
        
        let totalSessions = Double(completedSessions.count)
        return symptomCounts.mapValues { Double($0) / totalSessions }
    }
    
    static func negativeSessionPercentage(sessions: [PeeSession]) -> Double {
        let completedSessions = sessions.filter { $0.endTime != nil }
        guard !completedSessions.isEmpty else { return 0 }
        
        let negativeCount = completedSessions.filter { $0.feeling == .negative }.count
        return Double(negativeCount) / Double(completedSessions.count) * 100
    }
    
    // MARK: - Time-of-Day Analysis
    
    static func timeOfDayClustering(sessions: [PeeSession]) -> [TimeCluster: Int] {
        var clusters: [TimeCluster: Int] = [:]
        
        sessions.filter { $0.endTime != nil }.forEach { session in
            let hour = Calendar.current.component(.hour, from: session.startTime)
            let cluster = TimeCluster.from(hour: hour)
            clusters[cluster, default: 0] += 1
        }
        
        return clusters
    }
    
    static func nighttimeFrequency(sessions: [PeeSession]) -> Int {
        sessions.filter { session in
            guard session.endTime != nil else { return false }
            let hour = Calendar.current.component(.hour, from: session.startTime)
            return hour >= 22 || hour < 6
        }.count
    }
    
    // MARK: - Trend Analysis
    
    static func detectFrequencyTrend(sessions: [PeeSession], period: TrendPeriod) -> Trend {
        let now = Date()
        let calendar = Calendar.current
        
        let currentPeriodStart = period.startDate(from: now)
        let previousPeriodStart = period.previousPeriodStart(from: currentPeriodStart)
        let previousPeriodEnd = currentPeriodStart
        
        let currentSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= currentPeriodStart && endTime <= now
        }
        
        let previousSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= previousPeriodStart && endTime < previousPeriodEnd
        }
        
        let currentCount = currentSessions.count
        let previousCount = previousSessions.count
        
        if currentCount > previousCount {
            let increase = Double(currentCount - previousCount) / Double(max(previousCount, 1)) * 100
            return .increasing(percentage: increase)
        } else if currentCount < previousCount {
            let decrease = Double(previousCount - currentCount) / Double(max(previousCount, 1)) * 100
            return .decreasing(percentage: decrease)
        } else {
            return .stable
        }
    }
    
    static func detectSymptomTrend(sessions: [PeeSession], symptom: Symptom, period: TrendPeriod) -> Trend {
        let now = Date()
        let currentPeriodStart = period.startDate(from: now)
        let previousPeriodStart = period.previousPeriodStart(from: currentPeriodStart)
        
        let currentSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= currentPeriodStart && endTime <= now
        }
        
        let previousSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= previousPeriodStart && endTime < currentPeriodStart
        }
        
        let currentSymptomCount = currentSessions.filter { $0.symptoms.contains(symptom) }.count
        let previousSymptomCount = previousSessions.filter { $0.symptoms.contains(symptom) }.count
        
        if currentSymptomCount > previousSymptomCount {
            let increase = Double(currentSymptomCount - previousSymptomCount) / Double(max(previousSymptomCount, 1)) * 100
            return .increasing(percentage: increase)
        } else if currentSymptomCount < previousSymptomCount {
            let decrease = Double(previousSymptomCount - currentSymptomCount) / Double(max(previousSymptomCount, 1)) * 100
            return .decreasing(percentage: decrease)
        } else {
            return .stable
        }
    }
    
    // MARK: - Weekly Insights
    
    static func generateWeeklyInsights(sessions: [PeeSession]) -> WeeklyInsights {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let weekSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= weekStart && endTime <= now
        }
        
        let avgPerDay = Double(weekSessions.count) / 7.0
        let totalSessions = weekSessions.count
        let mostCommon = mostCommonSymptoms(sessions: weekSessions, limit: 3)
        let timeCluster = timeOfDayClustering(sessions: weekSessions)
        let mostActiveTime = timeCluster.max(by: { $0.value < $1.value })?.key ?? .morning
        let nighttime = nighttimeFrequency(sessions: weekSessions)
        let negativePercentage = negativeSessionPercentage(sessions: weekSessions)
        
        return WeeklyInsights(
            averagePerDay: avgPerDay,
            totalSessions: totalSessions,
            mostCommonSymptoms: mostCommon,
            mostActiveTimeCluster: mostActiveTime,
            nighttimeSessions: nighttime,
            negativePercentage: negativePercentage
        )
    }
}

// MARK: - Supporting Types

enum DateRange {
    case day(Date)
    case week(Date)
    case month(Date)
    case custom(start: Date, end: Date)
    
    var numberOfDays: Int {
        let calendar = Calendar.current
        switch self {
        case .day:
            return 1
        case .week:
            return 7
        case .month(let date):
            return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        case .custom(let start, let end):
            return calendar.dateComponents([.day], from: start, to: end).day ?? 0
        }
    }
    
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        switch self {
        case .day(let refDate):
            return calendar.isDate(date, inSameDayAs: refDate)
        case .week(let refDate):
            return calendar.isDate(date, equalTo: refDate, toGranularity: .weekOfYear)
        case .month(let refDate):
            return calendar.isDate(date, equalTo: refDate, toGranularity: .month)
        case .custom(let start, let end):
            return date >= start && date <= end
        }
    }
}

enum TimeCluster: String, CaseIterable {
    case earlyMorning = "Early Morning (12am-6am)"
    case morning = "Morning (6am-12pm)"
    case afternoon = "Afternoon (12pm-6pm)"
    case evening = "Evening (6pm-12am)"
    
    static func from(hour: Int) -> TimeCluster {
        switch hour {
        case 0..<6: return .earlyMorning
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        default: return .evening
        }
    }
    
    var icon: String {
        switch self {
        case .earlyMorning: return "moon.stars.fill"
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "sunset.fill"
        }
    }
}

enum TrendPeriod {
    case week
    case month
    case threeMonths
    
    func startDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: date)!
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: date)!
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: date)!
        }
    }
    
    func previousPeriodStart(from currentStart: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: currentStart)!
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: currentStart)!
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: currentStart)!
        }
    }
}

enum Trend {
    case increasing(percentage: Double)
    case decreasing(percentage: Double)
    case stable
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up.circle.fill"
        case .decreasing: return "arrow.down.circle.fill"
        case .stable: return "equal.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .increasing: return "red"
        case .decreasing: return "green"
        case .stable: return "blue"
        }
    }
    
    var description: String {
        switch self {
        case .increasing(let pct): return "↑ \(String(format: "%.1f%%", pct))"
        case .decreasing(let pct): return "↓ \(String(format: "%.1f%%", pct))"
        case .stable: return "Stable"
        }
    }
}

struct WeeklyInsights {
    let averagePerDay: Double
    let totalSessions: Int
    let mostCommonSymptoms: [(Symptom, Int)]
    let mostActiveTimeCluster: TimeCluster
    let nighttimeSessions: Int
    let negativePercentage: Double
}
