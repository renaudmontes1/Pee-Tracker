//
//  SettingsView.swift
//  Uri Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if !os(watchOS) && canImport(UIKit)
import UIKit
#endif

struct SettingsView: View {
    let sessions: [PeeSession]
#if !os(watchOS)
    @State private var showingExportSheet = false
    @State private var showingDoctorSummary = false
    @State private var exportFormat: ExportFormat = .csv
    @State private var exportPeriod: TrendPeriod = .month
#endif
    
    var body: some View {
        NavigationStack {
            List {
#if !os(watchOS)
                // Export Section
                Section {
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        showingDoctorSummary = true
                    }) {
                        Label("Doctor Visit Summary", systemImage: "doc.text")
                    }
                } header: {
                    Text("Data Export")
                } footer: {
                    Text("Export your tracking data for medical consultations or personal records")
                }
#endif
                
                // Statistics Section
                Section {
                    HStack {
                        Text("Total Sessions")
                        Spacer()
                        Text("\(sessions.filter { $0.endTime != nil }.count)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Active Session")
                        Spacer()
                        Text(sessions.contains { $0.endTime == nil } ? "Yes" : "No")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("First Session")
                        Spacer()
                        if let first = sessions.last, let startTime = first.startTime {
                            Text(startTime.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No data")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Statistics")
                }
                
                // Privacy & Data Section
                Section {
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    NavigationLink {
                        DataManagementView()
                    } label: {
                        Label("Data Management", systemImage: "externaldrive")
                    }
                } header: {
                    Text("Privacy & Data")
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://www.claivel.com/uri-tracker/")!) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
#if !os(watchOS)
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(sessions: sessions, isPresented: $showingExportSheet)
            }
            .sheet(isPresented: $showingDoctorSummary) {
                DoctorSummaryView(sessions: sessions, isPresented: $showingDoctorSummary)
            }
#endif
        }
    }
}

#if !os(watchOS)
// MARK: - Export Data View
struct ExportDataView: View {
    let sessions: [PeeSession]
    @Binding var isPresented: Bool
    @State private var exportFormat: ExportFormat = .csv
    @State private var exportPeriod: TrendPeriod = .month
    @State private var exportURL: URL?
    @State private var showingNoDataAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    
                    Picker("Period", selection: $exportPeriod) {
                        Text("Last Week").tag(TrendPeriod.week)
                        Text("Last Month").tag(TrendPeriod.month)
                        Text("Last 3 Months").tag(TrendPeriod.threeMonths)
                    }
                } header: {
                    Text("Export Options")
                }
                
                Section {
                    Text("Export will include all session data from the selected period in \(exportFormat.rawValue) format.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button(action: {
                        exportData()
                    }) {
                        HStack {
                            Spacer()
                            Label("Export Data", systemImage: "square.and.arrow.up")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("No Data to Export", isPresented: $showingNoDataAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("There are no completed sessions in the selected time period.")
            }
        }
        .onAppear {
            print("📱 ExportDataView appeared with \(sessions.count) sessions")
        }
    }
    
    private func exportData() {
        let now = Date()
        let startDate = exportPeriod.startDate(from: now)
        
        let filteredSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= startDate && endTime <= now
        }
        
        print("📊 Exporting \(filteredSessions.count) sessions in \(exportFormat.rawValue) format")
        
        // Check if there's data to export
        guard !filteredSessions.isEmpty else {
            print("⚠️ No sessions to export in selected period")
            showingNoDataAlert = true
            return
        }
        
        var url: URL?
        switch exportFormat {
        case .csv:
            url = ExportEngine.exportToCSV(sessions: filteredSessions)
        case .txt:
            url = ExportEngine.exportToTXT(sessions: filteredSessions, period: exportPeriod)
        }
        
        if let exportURL = url {
            print("✅ Export successful: \(exportURL.lastPathComponent)")
            // Use UIActivityViewController directly
            let activityVC = UIActivityViewController(activityItems: [exportURL], applicationActivities: nil)
            
            // Get the window scene to present from
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                // Find the topmost presented view controller
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                
                // For iPad - set popover presentation
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                topVC.present(activityVC, animated: true)
            }
        } else {
            print("❌ Export failed - no URL generated")
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case txt = "Text Summary"
}

// MARK: - Doctor Summary View
struct DoctorSummaryView: View {
    let sessions: [PeeSession]
    @Binding var isPresented: Bool
    @State private var period: TrendPeriod = .month
    @State private var showingShareSheet = false
    
    var summary: String {
        HealthInsightsEngine.generateDoctorSummary(sessions: sessions, period: period)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Period Selector
                    Picker("Period", selection: $period) {
                        Text("Last Week").tag(TrendPeriod.week)
                        Text("Last Month").tag(TrendPeriod.month)
                        Text("Last 3 Months").tag(TrendPeriod.threeMonths)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Summary Text
                    Text(summary)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    // Export Button
                    Button(action: {
                        UIPasteboard.general.string = summary
                        // Could also share as PDF here
                    }) {
                        Label("Copy to Clipboard", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
            }
            .navigationTitle("Doctor Visit Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: summary) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
#endif

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy & Security")
                    .font(.title2)
                    .fontWeight(.bold)
                
                PolicySection(
                    title: "Data Storage",
                    content: "All your health data is stored securely on your device and in your private iCloud account. We never access or sell your data."
                )
                
                PolicySection(
                    title: "CloudKit Sync",
                    content: "Data syncs between your devices using Apple's CloudKit framework with end-to-end encryption."
                )
                
                PolicySection(
                    title: "Data Sharing",
                    content: "You control all data exports. We never share your information with third parties."
                )
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Data Management View
struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    
    var body: some View {
        List {
            Section {
                Text("Your data is automatically backed up to iCloud and synced across your devices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("iCloud Sync")
            }
            
            Section {
                Button(role: .destructive, action: {
                    showingDeleteAlert = true
                }) {
                    Label("Delete All Data", systemImage: "trash")
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("This action cannot be undone. All your session data will be permanently deleted from all devices.")
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete All Data?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("Are you sure you want to delete all your tracking data? This cannot be undone.")
        }
    }
    
    private func deleteAllData() {
        let descriptor = FetchDescriptor<PeeSession>()
        if let sessions = try? modelContext.fetch(descriptor) {
            sessions.forEach { modelContext.delete($0) }
            try? modelContext.save()
        }
    }
}

// MARK: - Export Engine
class ExportEngine {
    static func exportToCSV(sessions: [PeeSession]) -> URL? {
        var csvString = "Date,Time,Duration (seconds),Feeling,Symptoms,Notes\n"
        
        sessions.sorted { 
            guard let start1 = $0.startTime, let start2 = $1.startTime else { return false }
            return start1 < start2
        }.forEach { session in
            guard let startTime = session.startTime,
                  let duration = session.duration,
                  let feeling = session.feeling else {
                return // Skip incomplete sessions
            }
            
            // Use custom formatters to avoid special characters
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let date = dateFormatter.string(from: startTime)
            
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"
            let time = timeFormatter.string(from: startTime)
            
            let durationInt = Int(duration)
            let feelingStr = feeling.rawValue
            let symptoms = (session.symptoms ?? []).map { $0.rawValue }.joined(separator: "; ")
            let notes = (session.notes ?? "").replacingOccurrences(of: ",", with: ";")
            
            csvString += "\"\(date)\",\"\(time)\",\(durationInt),\"\(feelingStr)\",\"\(symptoms)\",\"\(notes)\"\n"
        }
        
        // Use safe date format for filename (no slashes)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "PeeTracker_Export_\(timestamp).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            print("✅ CSV exported to: \(tempURL.path)")
            return tempURL
        } catch {
            print("❌ Error exporting CSV: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func exportToTXT(sessions: [PeeSession], period: TrendPeriod) -> URL? {
        let summary = HealthInsightsEngine.generateDoctorSummary(sessions: sessions, period: period)
        
        // Use safe date format for filename (no slashes)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "PeeTracker_Summary_\(timestamp).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try summary.write(to: tempURL, atomically: true, encoding: .utf8)
            print("✅ Summary exported to: \(tempURL.path)")
            return tempURL
        } catch {
            print("❌ Error exporting summary: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Share Sheet
#if !os(watchOS)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    SettingsView(sessions: [])
        .modelContainer(ModelContainer.shared)
}
