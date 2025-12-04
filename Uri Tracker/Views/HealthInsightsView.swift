//
//  HealthInsightsView.swift
//  Uri Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData

struct HealthInsightsView: View {
    let sessions: [PeeSession]
    
    var insights: [HealthInsight] {
        HealthInsightsEngine.generateInsights(sessions: sessions)
    }
    
    var criticalInsights: [HealthInsight] {
        insights.filter { $0.priority == .critical }
    }
    
    var highPriorityInsights: [HealthInsight] {
        insights.filter { $0.priority == .high }
    }
    
    var mediumPriorityInsights: [HealthInsight] {
        insights.filter { $0.priority == .medium }
    }
    
    var lowPriorityInsights: [HealthInsight] {
        insights.filter { $0.priority == .low }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if insights.isEmpty {
                    ContentUnavailableView(
                        "No Insights Yet",
                        systemImage: "brain.head.profile",
                        description: Text("Keep tracking to generate personalized health insights")
                    )
                    .frame(minHeight: 400)
                } else {
                    // Critical Insights
                    if !criticalInsights.isEmpty {
                        InsightSection(
                            title: "⚠️ Requires Immediate Attention",
                            insights: criticalInsights,
                            color: .red
                        )
                    }
                    
                    // High Priority
                    if !highPriorityInsights.isEmpty {
                        InsightSection(
                            title: "Important",
                            insights: highPriorityInsights,
                            color: .orange
                        )
                    }
                    
                    // Medium Priority
                    if !mediumPriorityInsights.isEmpty {
                        InsightSection(
                            title: "Worth Noting",
                            insights: mediumPriorityInsights,
                            color: .yellow
                        )
                    }
                    
                    // Low Priority (Positive)
                    if !lowPriorityInsights.isEmpty {
                        InsightSection(
                            title: "Good News",
                            insights: lowPriorityInsights,
                            color: .green
                        )
                    }
                }
                
                // Disclaimer
                Text("These insights are for informational purposes only and do not constitute medical advice. Always consult with a healthcare professional for medical concerns.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
        }
    .background(containerBackground)
    }
}

// MARK: - Insight Section
struct InsightSection: View {
    let title: String
    let insights: [HealthInsight]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(color)
            
            ForEach(insights) { insight in
                InsightCard(insight: insight)
            }
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: HealthInsight
    @State private var isExpanded = false
    
    var priorityColor: Color {
        switch insight.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: insight.priority.icon)
                    .foregroundStyle(priorityColor)
                
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Description
                    Text(insight.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    // Recommendation
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                            Text("Recommendation")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.blue)
                        
                        Text(insight.recommendation)
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
    .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: priorityColor.opacity(0.2), radius: 4, y: 2)
    }
}

private extension HealthInsightsView {
    var containerBackground: Color {
#if os(watchOS)
        Color.primary.opacity(0.05)
#else
        Color(.systemGroupedBackground)
#endif
    }
}

private extension InsightCard {
    var cardBackground: Color {
#if os(watchOS)
        Color.primary.opacity(0.08)
#else
    Color(.systemBackground)
#endif
    }
}

#Preview {
    let container = ModelContainer.shared
    let context = ModelContext(container)
    
    // Create sample sessions with various patterns
    for i in 0..<30 {
        let session = PeeSession(
            startTime: Date().addingTimeInterval(TimeInterval(-i * 3600 * 6)),
            endTime: Date().addingTimeInterval(TimeInterval(-i * 3600 * 6 + 60)),
            duration: 60,
            feeling: i % 4 == 0 ? .negative : .positive,
            symptoms: i % 4 == 0 ? [.pain, .weakStream, .burning] : [],
            notes: i % 5 == 0 ? "Feeling different today" : ""
        )
        context.insert(session)
    }
    
    return HealthInsightsView(sessions: [])
        .modelContainer(container)
}
