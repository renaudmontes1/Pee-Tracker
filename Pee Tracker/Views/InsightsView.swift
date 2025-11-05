//
//  InsightsView.swift
//  Pee Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    let sessions: [PeeSession]
    @StateObject private var syncMonitor = SyncMonitor.shared
    @State private var selectedTab: InsightsTab = .charts
    @State private var selectedTimeframe: ChartTimeframe = .week
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    ForEach(InsightsTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
#if !os(watchOS)
                .pickerStyle(.segmented)
#endif
                .padding()
                
                // Content
                if selectedTab == .aiInsights {
                    HealthInsightsView(sessions: sessions)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Timeframe Picker
                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(ChartTimeframe.allCases, id: \.self) { timeframe in
                                    Text(timeframe.rawValue).tag(timeframe)
                                }
                            }
#if !os(watchOS)
                            .pickerStyle(.segmented)
#endif
                            .padding(.horizontal)
                    
                            // Weekly Summary Card
                            if selectedTimeframe == .week {
                                WeeklySummaryCard(sessions: sessions)
                                    .padding(.horizontal)
                            }
                            
                            // Frequency Chart
                            FrequencyChartCard(sessions: sessions, timeframe: selectedTimeframe)
                                .padding(.horizontal)
                            
                            // Time of Day Distribution
                            TimeOfDayChartCard(sessions: sessions)
                                .padding(.horizontal)
                            
                            // Feeling Distribution
                            FeelingDistributionCard(sessions: sessions, timeframe: selectedTimeframe)
                                .padding(.horizontal)
                            
                            // Symptom Frequency
                            if sessions.contains(where: { !($0.symptoms ?? []).isEmpty }) {
                                SymptomFrequencyCard(sessions: sessions, timeframe: selectedTimeframe)
                                    .padding(.horizontal)
                            }
                            
                            // Trend Indicators
                            TrendIndicatorsCard(sessions: sessions)
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .background(Color.insightsContainerBackground)
                }
            }
            .navigationTitle("Insights")
        }
    }
}

enum InsightsTab: String, CaseIterable {
    case charts = "Charts"
    case aiInsights = "Health Insights"
}

// MARK: - Weekly Summary Card
struct WeeklySummaryCard: View {
    let sessions: [PeeSession]
    
    var insights: WeeklyInsights {
        AnalyticsEngine.generateWeeklyInsights(sessions: sessions)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                Text("This Week")
                    .font(.headline)
            }
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    StatBox(
                        title: "Avg/Day",
                        value: String(format: "%.1f", insights.averagePerDay),
                        icon: "chart.bar.fill"
                    )
                    
                    StatBox(
                        title: "Total",
                        value: "\(insights.totalSessions)",
                        icon: "number"
                    )
                }
                
                GridRow {
                    StatBox(
                        title: "Nighttime",
                        value: "\(insights.nighttimeSessions)",
                        icon: "moon.stars.fill"
                    )
                    
                    StatBox(
                        title: "Negative",
                        value: String(format: "%.0f%%", insights.negativePercentage),
                        icon: "exclamationmark.triangle.fill",
                        color: insights.negativePercentage > 20 ? .red : .green
                    )
                }
            }
            
            if !insights.mostCommonSymptoms.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Most Common Symptoms")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ForEach(insights.mostCommonSymptoms, id: \.0) { symptom, count in
                        HStack {
                            Text(symptom.icon)
                            Text(symptom.rawValue)
                                .font(.callout)
                            Spacer()
                            Text("\(count)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
    .background(Color.insightsCardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Frequency Chart Card
struct FrequencyChartCard: View {
    let sessions: [PeeSession]
    let timeframe: ChartTimeframe
    
    var chartData: [SessionDataPoint] {
        let calendar = Calendar.current
        let now = Date()
        let startDate = timeframe.startDate(from: now)
        
        let filteredSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= startDate && endTime <= now
        }
        
        var groupedSessions: [Date: Int] = [:]
        
        switch timeframe {
        case .day:
            // Group by hour
            for hour in 0..<24 {
                if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: now) {
                    groupedSessions[date] = 0
                }
            }
            
            filteredSessions.forEach { session in
                guard let startTime = session.startTime else { return }
                let hour = calendar.component(.hour, from: startTime)
                if let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: startTime) {
                    groupedSessions[hourStart, default: 0] += 1
                }
            }
            
        case .week:
            // Group by day
            for dayOffset in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                    let dayStart = calendar.startOfDay(for: date)
                    groupedSessions[dayStart] = 0
                }
            }
            
            filteredSessions.forEach { session in
                guard let startTime = session.startTime else { return }
                let dayStart = calendar.startOfDay(for: startTime)
                groupedSessions[dayStart, default: 0] += 1
            }
            
        case .month, .threeMonths, .sixMonths, .year:
            // Group by day
            let days = timeframe.numberOfDays
            for dayOffset in 0..<days {
                if let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) {
                    let dayStart = calendar.startOfDay(for: date)
                    groupedSessions[dayStart] = 0
                }
            }
            
            filteredSessions.forEach { session in
                guard let startTime = session.startTime else { return }
                let dayStart = calendar.startOfDay(for: startTime)
                groupedSessions[dayStart, default: 0] += 1
            }
        }
        
        return groupedSessions
            .map { SessionDataPoint(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.blue)
                Text("Session Frequency")
                    .font(.headline)
            }
            
            if chartData.isEmpty {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(chartData) { dataPoint in
                    BarMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Count", dataPoint.count)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisValueLabel(format: timeframe.xAxisFormat)
                    }
                }
            }
        }
        .padding()
    .background(Color.insightsCardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct SessionDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

// MARK: - Time of Day Chart Card
struct TimeOfDayChartCard: View {
    let sessions: [PeeSession]
    
    var timeDistribution: [TimeDistributionData] {
        let clusters = AnalyticsEngine.timeOfDayClustering(sessions: sessions)
        return TimeCluster.allCases.map { cluster in
            TimeDistributionData(cluster: cluster, count: clusters[cluster] ?? 0)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.orange)
                Text("Time of Day Distribution")
                    .font(.headline)
            }
            
            if timeDistribution.allSatisfy({ $0.count == 0 }) {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(timeDistribution) { data in
                    SectorMark(
                        angle: .value("Count", data.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Time", data.cluster.rawValue))
                    .cornerRadius(4)
                }
                .frame(height: 200)
                
                // Legend
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(timeDistribution) { data in
                        if data.count > 0 {
                            HStack {
                                Image(systemName: data.cluster.icon)
                                    .foregroundStyle(colorForCluster(data.cluster))
                                Text(data.cluster.rawValue)
                                    .font(.caption)
                                Spacer()
                                Text("\(data.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
    .background(Color.insightsCardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private func colorForCluster(_ cluster: TimeCluster) -> Color {
        switch cluster {
        case .earlyMorning: return .indigo
        case .morning: return .orange
        case .afternoon: return .yellow
        case .evening: return .purple
        }
    }
}

struct TimeDistributionData: Identifiable {
    let id = UUID()
    let cluster: TimeCluster
    let count: Int
}

// MARK: - Feeling Distribution Card
struct FeelingDistributionCard: View {
    let sessions: [PeeSession]
    let timeframe: ChartTimeframe
    
    var feelingData: [FeelingData] {
        let now = Date()
        let startDate = timeframe.startDate(from: now)
        
        let filteredSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= startDate && endTime <= now
        }
        
        let positiveCount = filteredSessions.filter { $0.feeling == .positive }.count
        let negativeCount = filteredSessions.filter { $0.feeling == .negative }.count
        
        return [
            FeelingData(feeling: .positive, count: positiveCount),
            FeelingData(feeling: .negative, count: negativeCount)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                Text("Feeling Distribution")
                    .font(.headline)
            }
            
            HStack(spacing: 16) {
                ForEach(feelingData) { data in
                    let total = feelingData.reduce(0) { $0 + $1.count }
                    let percentage = total > 0 ? Int(Double(data.count) / Double(total) * 100) : 0
                    let backgroundColor = data.feeling == .positive ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
                    
                    VStack(spacing: 8) {
                        Text(data.feeling.emoji)
                            .font(.system(size: 40))
                        Text(data.feeling.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(data.count)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if total > 0 {
                            Text("\(percentage)%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(backgroundColor)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    .background(Color.insightsCardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct FeelingData: Identifiable {
    let id = UUID()
    let feeling: SessionFeeling
    let count: Int
}

// MARK: - Symptom Frequency Card
struct SymptomFrequencyCard: View {
    let sessions: [PeeSession]
    let timeframe: ChartTimeframe
    
    var symptomData: [SymptomData] {
        let now = Date()
        let startDate = timeframe.startDate(from: now)
        
        let filteredSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= startDate && endTime <= now
        }
        
        return AnalyticsEngine.mostCommonSymptoms(sessions: filteredSessions, limit: 10)
            .map { SymptomData(symptom: $0.0, count: $0.1) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundStyle(.red)
                Text("Symptom Frequency")
                    .font(.headline)
            }
            
            if symptomData.isEmpty {
                Text("No symptoms recorded")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                Chart(symptomData) { data in
                    BarMark(
                        x: .value("Count", data.count),
                        y: .value("Symptom", "\(data.symptom.icon) \(data.symptom.rawValue)")
                    )
                    .foregroundStyle(Color.red.gradient)
                }
                .frame(height: CGFloat(symptomData.count * 40))
            }
        }
        .padding()
    .background(Color.insightsCardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct SymptomData: Identifiable {
    let id = UUID()
    let symptom: Symptom
    let count: Int
}

// MARK: - Trend Indicators Card
struct TrendIndicatorsCard: View {
    let sessions: [PeeSession]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundStyle(.purple)
                Text("Trends")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                TrendRow(
                    title: "Frequency (vs last week)",
                    trend: AnalyticsEngine.detectFrequencyTrend(sessions: sessions, period: .week)
                )
                
                TrendRow(
                    title: "Frequency (vs last month)",
                    trend: AnalyticsEngine.detectFrequencyTrend(sessions: sessions, period: .month)
                )
            }
        }
        .padding()
    .background(Color.insightsCardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct TrendRow: View {
    let title: String
    let trend: Trend
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: trend.icon)
                Text(trend.description)
            }
            .font(.subheadline)
            .foregroundStyle(trendColor)
        }
        .padding(.vertical, 4)
    }
    
    var trendColor: Color {
        switch trend {
        case .increasing: return .red
        case .decreasing: return .green
        case .stable: return .blue
        }
    }
}

private extension Color {
    static var insightsContainerBackground: Color {
#if os(watchOS)
    Color.primary.opacity(0.05)
#else
    Color(.systemGroupedBackground)
#endif
    }
    
    static var insightsCardBackground: Color {
#if os(watchOS)
    Color.primary.opacity(0.08)
#else
    Color(.systemBackground)
#endif
    }
}

// MARK: - Supporting Types

enum ChartTimeframe: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case year = "Year"
    
    func startDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .day:
            return calendar.startOfDay(for: date)
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: date)!
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: date)!
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: date)!
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: date)!
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: date)!
        }
    }
    
    var numberOfDays: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        }
    }
    
    var xAxisFormat: Date.FormatStyle {
        switch self {
        case .day:
            return .dateTime.hour()
        case .week:
            return .dateTime.weekday(.abbreviated)
        case .month:
            return .dateTime.day()
        case .threeMonths, .sixMonths:
            return .dateTime.month(.abbreviated).day()
        case .year:
            return .dateTime.month(.abbreviated)
        }
    }
}

#Preview {
    let container = ModelContainer.shared
    let context = ModelContext(container)
    
    // Create sample sessions
    for i in 0..<20 {
        let session = PeeSession(
            startTime: Date().addingTimeInterval(TimeInterval(-i * 3600 * 6)),
            endTime: Date().addingTimeInterval(TimeInterval(-i * 3600 * 6 + 60)),
            duration: 60,
            feeling: i % 3 == 0 ? .negative : .positive,
            symptoms: i % 3 == 0 ? [.pain, .dripping] : []
        )
        context.insert(session)
    }
    
    return InsightsView(sessions: [])
        .modelContainer(container)
}
