//
//  SyncDebugView.swift
//  Pee Tracker Watch App
//
//  Sync diagnostics and debugging information
//

import SwiftUI
import CloudKit
import SwiftData

struct SyncDebugView: View {
    @ObservedObject var syncMonitor = SyncMonitor.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var containerID: String = "Loading..."
    @State private var accountStatus: String = "Checking..."
    @State private var lastSyncTime: String = "Never"
    @State private var localSessionCount: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // CloudKit Container
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Container ID")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(containerID)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    
                    Divider()
                    
                    // Account Status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iCloud Account")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: accountStatusIcon)
                                .foregroundStyle(accountStatusColor)
                            Text(accountStatus)
                                .font(.caption2)
                        }
                    }
                    
                    Divider()
                    
                    // Current Sync Status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sync Status")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text(statusText)
                                .font(.caption2)
                        }
                    }
                    
                    Divider()
                    
                    // Local Session Count
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Local Sessions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Image(systemName: "tray.full.fill")
                                .foregroundStyle(.blue)
                            Text("\(localSessionCount) sessions stored")
                                .font(.caption2)
                        }
                    }
                    
                    Divider()
                    
                    // Sync Logs
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Activity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if syncMonitor.syncLogs.isEmpty {
                            Text("No sync activity yet")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            ForEach(syncMonitor.syncLogs.suffix(10).reversed(), id: \.timestamp) { log in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: log.icon)
                                        .font(.caption2)
                                        .foregroundStyle(log.color)
                                        .frame(width: 12)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(log.message)
                                            .font(.caption2)
                                        Text(log.timestamp, style: .time)
                                            .font(.system(size: 9))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Sync Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkCloudKitStatus()
            }
        }
    }
    
    private var statusColor: Color {
        switch syncMonitor.status {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
        switch syncMonitor.status {
        case .idle:
            return "Idle"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Success"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var accountStatusIcon: String {
        switch accountStatus {
        case "Available":
            return "checkmark.circle.fill"
        case "Not Available", "Restricted", "No Account":
            return "xmark.circle.fill"
        default:
            return "questionmark.circle"
        }
    }
    
    private var accountStatusColor: Color {
        switch accountStatus {
        case "Available":
            return .green
        case "Not Available", "Restricted", "No Account":
            return .red
        default:
            return .orange
        }
    }
    
    private func checkCloudKitStatus() {
        // Get container ID
        containerID = "iCloud.rens-corp.Pee-Pee-Tracker"
        
        // Check account status
        let container = CKContainer(identifier: containerID)
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    accountStatus = "Error: \(error.localizedDescription)"
                } else {
                    switch status {
                    case .available:
                        accountStatus = "Available"
                    case .noAccount:
                        accountStatus = "No Account"
                    case .restricted:
                        accountStatus = "Restricted"
                    case .couldNotDetermine:
                        accountStatus = "Could Not Determine"
                    case .temporarilyUnavailable:
                        accountStatus = "Temporarily Unavailable"
                    @unknown default:
                        accountStatus = "Unknown"
                    }
                }
            }
        }
        
        // Update last sync time
        if let lastLog = syncMonitor.syncLogs.last {
            lastSyncTime = lastLog.timestamp.formatted(date: .omitted, time: .shortened)
        }
        
        // Count local sessions
        let descriptor = FetchDescriptor<PeeSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        if let sessions = try? modelContext.fetch(descriptor) {
            localSessionCount = sessions.count
            SyncMonitor.shared.logEvent("Local database has \(localSessionCount) sessions", type: .info)
        }
    }
}

#Preview {
    SyncDebugView()
}
