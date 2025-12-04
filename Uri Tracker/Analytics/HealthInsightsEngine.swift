//
//  HealthInsightsEngine.swift
//  Uri Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import Foundation

class HealthInsightsEngine {
    
    // MARK: - Generate Insights
    
    static func generateInsights(sessions: [PeeSession]) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Frequency Analysis
        insights.append(contentsOf: analyzeFrequency(sessions: sessions))
        
        // Symptom Pattern Analysis
        insights.append(contentsOf: analyzeSymptomPatterns(sessions: sessions))
        
        // Nighttime Frequency
        insights.append(contentsOf: analyzeNighttimeFrequency(sessions: sessions))
        
        // Hydration Insights
        insights.append(contentsOf: analyzeHydration(sessions: sessions))
        
        // Trend-based Insights
        insights.append(contentsOf: analyzeTrends(sessions: sessions))
        
        // Sort by priority
        return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Frequency Analysis
    
    private static func analyzeFrequency(sessions: [PeeSession]) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let weekSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= weekStart
        }
        
        let avgPerDay = Double(weekSessions.count) / 7.0
        
        // Normal range is 6-8 times per day
        if avgPerDay > 10 {
            insights.append(HealthInsight(
                title: "High Urination Frequency",
                description: "You're averaging \(String(format: "%.1f", avgPerDay)) sessions per day, which is higher than normal (6-8/day). This could indicate overhydration, diabetes, or urinary tract infection.",
                recommendation: "Consider tracking your fluid intake and consult with a healthcare provider if this persists.",
                priority: .high,
                category: .frequency
            ))
        } else if avgPerDay < 4 {
            insights.append(HealthInsight(
                title: "Low Urination Frequency",
                description: "You're averaging \(String(format: "%.1f", avgPerDay)) sessions per day, which is lower than normal (6-8/day). This might suggest dehydration.",
                recommendation: "Increase your fluid intake to 8-10 glasses of water per day and monitor for improvement.",
                priority: .medium,
                category: .frequency
            ))
        } else if avgPerDay >= 6 && avgPerDay <= 8 {
            insights.append(HealthInsight(
                title: "Healthy Frequency",
                description: "Your urination frequency of \(String(format: "%.1f", avgPerDay)) sessions per day is within the normal range.",
                recommendation: "Keep up your current hydration habits!",
                priority: .low,
                category: .frequency
            ))
        }
        
        return insights
    }
    
    // MARK: - Symptom Pattern Analysis
    
    private static func analyzeSymptomPatterns(sessions: [PeeSession]) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        let calendar = Calendar.current
        let now = Date()
        let twoWeeksStart = calendar.date(byAdding: .day, value: -14, to: now)!
        
        let recentSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= twoWeeksStart
        }
        
        let symptomCounts = AnalyticsEngine.mostCommonSymptoms(sessions: recentSessions)
        
        // Blood detection
        if let bloodCount = symptomCounts.first(where: { $0.0 == .blood })?.1, bloodCount > 0 {
            insights.append(HealthInsight(
                title: "⚠️ Blood Detected",
                description: "You've reported blood in your urine \(bloodCount) time(s) in the past two weeks. This requires immediate medical attention.",
                recommendation: "Seek medical evaluation immediately. Blood in urine (hematuria) can indicate infection, kidney stones, or other serious conditions.",
                priority: .critical,
                category: .symptoms
            ))
        }
        
        // Pain analysis
        if let painCount = symptomCounts.first(where: { $0.0 == .pain })?.1, painCount >= 3 {
            insights.append(HealthInsight(
                title: "Recurring Pain",
                description: "You've experienced pain during \(painCount) sessions in the past two weeks.",
                recommendation: "Persistent pain could indicate a urinary tract infection, kidney stones, or prostate issues. Schedule an appointment with your healthcare provider.",
                priority: .high,
                category: .symptoms
            ))
        }
        
        // Incomplete emptying pattern
        if let emptyCount = symptomCounts.first(where: { $0.0 == .incomplete })?.1, emptyCount >= 5 {
            let percentage = Double(emptyCount) / Double(recentSessions.count) * 100
            insights.append(HealthInsight(
                title: "Incomplete Bladder Emptying",
                description: "You've reported not feeling fully empty in \(String(format: "%.0f%%", percentage)) of your sessions.",
                recommendation: "This could indicate benign prostatic hyperplasia (BPH) or bladder dysfunction. Consider pelvic floor exercises and consult a urologist.",
                priority: .medium,
                category: .symptoms
            ))
        }
        
        // Weak stream pattern
        if let weakStreamCount = symptomCounts.first(where: { $0.0 == .weakStream })?.1, weakStreamCount >= 5 {
            insights.append(HealthInsight(
                title: "Weak Urine Stream",
                description: "You've experienced weak stream in \(weakStreamCount) sessions recently.",
                recommendation: "This is common with age or prostate enlargement. Try double voiding (urinate, wait a moment, then try again) and consider pelvic floor strengthening.",
                priority: .medium,
                category: .symptoms
            ))
        }
        
        // Burning sensation pattern
        if let burningCount = symptomCounts.first(where: { $0.0 == .burning })?.1, burningCount >= 3 {
            insights.append(HealthInsight(
                title: "Burning Sensation",
                description: "You've experienced burning while urinating in \(burningCount) recent sessions.",
                recommendation: "Burning sensation often indicates urinary tract infection (UTI) or inflammation. Increase water intake and consult a healthcare provider if symptoms persist.",
                priority: .high,
                category: .symptoms
            ))
        }
        
        // Hesitancy pattern
        if let hesitancyCount = symptomCounts.first(where: { $0.0 == .hesitancy })?.1, hesitancyCount >= 5 {
            insights.append(HealthInsight(
                title: "Difficulty Initiating Flow",
                description: "You've had trouble starting urination in \(hesitancyCount) sessions.",
                recommendation: "Hesitancy can be related to prostate issues or pelvic floor tension. Relaxation techniques and medical evaluation may help.",
                priority: .medium,
                category: .symptoms
            ))
        }
        
        // Urgency pattern
        if let urgencyCount = symptomCounts.first(where: { $0.0 == .urgency })?.1, urgencyCount >= 7 {
            let percentage = Double(urgencyCount) / Double(recentSessions.count) * 100
            insights.append(HealthInsight(
                title: "Frequent Urgent Urges",
                description: "You've experienced urgent needs to urinate in \(String(format: "%.0f%%", percentage)) of sessions.",
                recommendation: "Urgency can indicate overactive bladder. Bladder training exercises, reducing caffeine/alcohol, and medical consultation may help.",
                priority: .high,
                category: .symptoms
            ))
        }
        
        return insights
    }
    
    // MARK: - Nighttime Analysis
    
    private static func analyzeNighttimeFrequency(sessions: [PeeSession]) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let nighttimeCount = sessions.filter { session in
            guard let endTime = session.endTime, 
                  let startTime = session.startTime,
                  endTime >= weekStart else { return false }
            let hour = calendar.component(.hour, from: startTime)
            return hour >= 22 || hour < 6
        }.count
        
        let avgNighttimePerNight = Double(nighttimeCount) / 7.0
        
        if avgNighttimePerNight >= 2 {
            insights.append(HealthInsight(
                title: "Nocturia (Nighttime Urination)",
                description: "You're waking up an average of \(String(format: "%.1f", avgNighttimePerNight)) times per night to urinate.",
                recommendation: "Limit fluids 2-3 hours before bedtime, avoid caffeine and alcohol in the evening, and elevate your legs in the afternoon. If persistent, consult your doctor about possible sleep apnea or heart conditions.",
                priority: .medium,
                category: .patterns
            ))
        }
        
        return insights
    }
    
    // MARK: - Hydration Analysis
    
    private static func analyzeHydration(sessions: [PeeSession]) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let weekSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= weekStart
        }
        
        // Check session duration patterns
        let avgDuration = AnalyticsEngine.averageDuration(sessions: weekSessions)
        
        if avgDuration < 5 {
            insights.append(HealthInsight(
                title: "Short Duration Sessions",
                description: "Your sessions are averaging only \(Int(avgDuration)) seconds, which might indicate inadequate hydration or bladder irritation.",
                recommendation: "Ensure you're drinking enough water throughout the day. Aim for clear to pale yellow urine color.",
                priority: .low,
                category: .hydration
            ))
        }
        
        // Check for clustering (might indicate overconsumption)
        let timeDistribution = AnalyticsEngine.timeOfDayClustering(sessions: weekSessions)
        if let maxCluster = timeDistribution.max(by: { $0.value < $1.value }),
           Double(maxCluster.value) / Double(weekSessions.count) > 0.5 {
            insights.append(HealthInsight(
                title: "Uneven Hydration Pattern",
                description: "Most of your sessions occur during \(maxCluster.key.rawValue.lowercased()).",
                recommendation: "Try to distribute your fluid intake more evenly throughout the day for better bladder health.",
                priority: .medium,
                category: .patterns
            ))
        }
        
        return insights
    }
    
    // MARK: - Trend Analysis
    
    private static func analyzeTrends(sessions: [PeeSession]) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Analyze monthly trends (weekly trend reserved for future use)
        let monthTrend = AnalyticsEngine.detectFrequencyTrend(sessions: sessions, period: .month)
        
        switch monthTrend {
        case .increasing(let percentage) where percentage > 30:
            insights.append(HealthInsight(
                title: "Increasing Frequency Trend",
                description: "Your urination frequency has increased by \(String(format: "%.0f%%", percentage)) over the past month.",
                recommendation: "This significant increase warrants medical evaluation. Track any new medications, dietary changes, or other symptoms to discuss with your doctor.",
                priority: .high,
                category: .trends
            ))
            
        case .decreasing(let percentage) where percentage > 30:
            insights.append(HealthInsight(
                title: "Decreasing Frequency Trend",
                description: "Your urination frequency has decreased by \(String(format: "%.0f%%", percentage)) over the past month.",
                recommendation: "Ensure you're maintaining adequate hydration. If accompanied by dark urine or other symptoms, consult a healthcare provider.",
                priority: .medium,
                category: .trends
            ))
            
        default:
            break
        }
        
        // Check symptom trends
        for symptom in Symptom.allCases {
            let trend = AnalyticsEngine.detectSymptomTrend(sessions: sessions, symptom: symptom, period: .month)
            
            if case .increasing(let percentage) = trend, percentage > 50 {
                insights.append(HealthInsight(
                    title: "Worsening \(symptom.rawValue)",
                    description: "Your \(symptom.rawValue.lowercased()) symptoms have increased by \(String(format: "%.0f%%", percentage)) this month.",
                    recommendation: "Schedule an appointment with your healthcare provider to evaluate this worsening symptom.",
                    priority: .high,
                    category: .symptoms
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Doctor Visit Summary
    
    static func generateDoctorSummary(sessions: [PeeSession], period: TrendPeriod = .month) -> String {
        let now = Date()
        let startDate = period.startDate(from: now)
        
        let relevantSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= startDate
        }
        
        let avgPerDay = Double(relevantSessions.count) / Double(period.numberOfDays)
        let negativePercentage = AnalyticsEngine.negativeSessionPercentage(sessions: relevantSessions)
        let symptoms = AnalyticsEngine.mostCommonSymptoms(sessions: relevantSessions)
        let nighttime = AnalyticsEngine.nighttimeFrequency(sessions: relevantSessions)
        let avgDuration = AnalyticsEngine.averageDuration(sessions: relevantSessions)
        
        var summary = """
        URINARY HEALTH SUMMARY
        Period: \(startDate.formatted(date: .abbreviated, time: .omitted)) - \(now.formatted(date: .abbreviated, time: .omitted))
        
        FREQUENCY:
        • Average sessions per day: \(String(format: "%.1f", avgPerDay))
        • Total sessions: \(relevantSessions.count)
        • Nighttime sessions: \(nighttime)
        • Average duration: \(Int(avgDuration)) seconds
        
        SYMPTOMS:
        • Sessions with issues: \(String(format: "%.0f%%", negativePercentage))
        """
        
        if !symptoms.isEmpty {
            summary += "\n• Most common symptoms:"
            for (symptom, count) in symptoms {
                let percentage = Double(count) / Double(relevantSessions.count) * 100
                summary += "\n  - \(symptom.rawValue): \(count) times (\(String(format: "%.0f%%", percentage)))"
            }
        }
        
        summary += "\n\nTRENDS:"
        let trend = AnalyticsEngine.detectFrequencyTrend(sessions: sessions, period: period)
        summary += "\n• Frequency trend: \(trend.description)"
        
        return summary
    }
}

// MARK: - Supporting Types

struct HealthInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let recommendation: String
    let priority: InsightPriority
    let category: InsightCategory
}

enum InsightPriority: Int {
    case critical = 4
    case high = 3
    case medium = 2
    case low = 1
    
    var color: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange"
        case .medium: return "yellow"
        case .low: return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "checkmark.circle.fill"
        }
    }
}

enum InsightCategory: String {
    case frequency = "Frequency"
    case symptoms = "Symptoms"
    case patterns = "Patterns"
    case hydration = "Hydration"
    case trends = "Trends"
}

// Extension for period days
extension TrendPeriod {
    var numberOfDays: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        }
    }
}
