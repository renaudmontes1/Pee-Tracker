//
//  SettingsView.swift
//  Pee Tracker
//
//  Created by Renaud Montes on 10/27/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    let sessions: [PeeSession]
    @State private var showingExportSheet = false
    @State private var showingDoctorSummary = false
    @State private var exportFormat: ExportFormat = .pdf
    @State private var exportPeriod: TrendPeriod = .month
    
    var body: some View {
        NavigationStack {
            List {
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
                    
                    Link(destination: URL(string: "https://example.com/support")!) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(sessions: sessions, isPresented: $showingExportSheet)
            }
            .sheet(isPresented: $showingDoctorSummary) {
                DoctorSummaryView(sessions: sessions, isPresented: $showingDoctorSummary)
            }
        }
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    let sessions: [PeeSession]
    @Binding var isPresented: Bool
    @State private var exportFormat: ExportFormat = .csv
    @State private var exportPeriod: TrendPeriod = .month
    @State private var showingShareSheet = false
    @State private var exportURL: URL?
    
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
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private func exportData() {
        let now = Date()
        let startDate = exportPeriod.startDate(from: now)
        
        let filteredSessions = sessions.filter { session in
            guard let endTime = session.endTime else { return false }
            return endTime >= startDate && endTime <= now
        }
        
        switch exportFormat {
        case .csv:
            exportURL = ExportEngine.exportToCSV(sessions: filteredSessions)
        case .pdf:
            exportURL = ExportEngine.exportToPDF(sessions: filteredSessions, period: exportPeriod)
        }
        
        if exportURL != nil {
            showingShareSheet = true
        }
    }
}

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case pdf = "PDF"
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
                    title: "HIPAA Compliance",
                    content: "While this app helps you track health information, it is designed for personal use. For HIPAA-compliant medical record keeping, consult your healthcare provider."
                )
                
                PolicySection(
                    title: "Data Sharing",
                    content: "You control all data exports. We never automatically share your information with third parties."
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
            
            let date = startTime.formatted(date: .numeric, time: .omitted)
            let time = startTime.formatted(date: .omitted, time: .shortened)
            let durationInt = Int(duration)
            let feelingStr = feeling.rawValue
            let symptoms = (session.symptoms ?? []).map { $0.rawValue }.joined(separator: "; ")
            let notes = (session.notes ?? "").replacingOccurrences(of: ",", with: ";")
            
            csvString += "\"\(date)\",\"\(time)\",\(durationInt),\"\(feelingStr)\",\"\(symptoms)\",\"\(notes)\"\n"
        }
        
        let fileName = "PeeTracker_Export_\(Date().formatted(date: .numeric, time: .omitted)).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Error exporting CSV: \(error)")
            return nil
        }
    }
    
    static func exportToPDF(sessions: [PeeSession], period: TrendPeriod) -> URL? {
        // For simplicity, we'll create a text-based PDF
        // In production, you'd use PDFKit for proper formatting
        let summary = HealthInsightsEngine.generateDoctorSummary(sessions: sessions, period: period)
        let fileName = "PeeTracker_Summary_\(Date().formatted(date: .numeric, time: .omitted)).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try summary.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Error exporting PDF: \(error)")
            return nil
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView(sessions: [])
        .modelContainer(ModelContainer.shared)
}
