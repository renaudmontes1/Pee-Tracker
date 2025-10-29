//
//  SyncMonitor.swift
//  Pee Tracker
//
//  Created by GitHub Copilot on 10/27/25.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Sync Log Entry
struct SyncLogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let type: LogType
    
    enum LogType {
        case info
        case success
        case error
        case warning
    }
    
    var icon: String {
        switch type {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch type {
        case .info: return .blue
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        }
    }
}

enum SyncStatus: Equatable {
    case idle
    case syncing
    case success
    case error(String)
    
    var icon: String {
        switch self {
        case .idle: return "icloud"
        case .syncing: return "icloud.and.arrow.up"
        case .success: return "icloud.and.arrow.up"
        case .error: return "icloud.slash"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .syncing: return .blue
        case .success: return .green
        case .error: return .red
        }
    }
    
    var message: String {
        switch self {
        case .idle: return "Not syncing"
        case .syncing: return "Syncing..."
        case .success: return "Synced"
        case .error(let message): return message
        }
    }
}

@MainActor
class SyncMonitor: ObservableObject {
    @Published var status: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var syncLogs: [SyncLogEntry] = []
    
    private var syncTimer: Timer?
    private var successTimer: Timer?
    private let maxLogEntries = 50 // Keep last 50 log entries
    
    static let shared = SyncMonitor()
    
    private init() {
        addLog("Sync monitor initialized", type: .info)
        startMonitoring()
    }
    
    func startMonitoring() {
        // Reset any existing timers
        syncTimer?.invalidate()
        
        // Check sync status every 5 seconds
        syncTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.checkSyncStatus()
            }
        }
        addLog("Monitoring started", type: .info)
    }
    
    func stopMonitoring() {
        syncTimer?.invalidate()
        syncTimer = nil
        successTimer?.invalidate()
        successTimer = nil
        addLog("Monitoring stopped", type: .info)
    }
    
    func reportSyncStarted() {
        status = .syncing
        successTimer?.invalidate()
        addLog("Sync started", type: .info)
    }
    
    func reportSyncSuccess() {
        status = .success
        lastSyncTime = Date()
        addLog("Sync completed successfully", type: .success)
        
        // Show success for 3 seconds, then go back to idle
        successTimer?.invalidate()
        successTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                if case .success = self?.status {
                    self?.status = .idle
                }
            }
        }
    }
    
    func reportSyncError(_ error: String) {
        status = .error(error)
        addLog("Sync error: \(error)", type: .error)
    }
    
    private func checkSyncStatus() {
        // This is a simple heuristic - if we haven't seen any activity,
        // we assume things are idle
        if case .syncing = status {
            // If we've been syncing for more than 30 seconds, something might be wrong
            // But we'll let CloudKit handle retries
        }
    }
    
    // Public method to add custom log entries
    func logEvent(_ message: String, type: SyncLogEntry.LogType) {
        addLog(message, type: type)
    }
    
    private func addLog(_ message: String, type: SyncLogEntry.LogType) {
        let entry = SyncLogEntry(timestamp: Date(), message: message, type: type)
        syncLogs.append(entry)
        
        // Keep only the most recent entries
        if syncLogs.count > maxLogEntries {
            syncLogs.removeFirst(syncLogs.count - maxLogEntries)
        }
        
        print("📝 [SyncLog] \(message)")
    }
}

// Sync Status Badge View
struct SyncStatusBadge: View {
    @ObservedObject var monitor: SyncMonitor
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: monitor.status.icon)
                .foregroundStyle(monitor.status.color)
                .symbolEffect(.pulse, isActive: isAnimating)
            
            Text(monitor.status.message)
                .font(.caption)
                .foregroundStyle(monitor.status.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(monitor.status.color.opacity(0.1))
        .cornerRadius(12)
        .onChange(of: monitor.status) { oldValue, newValue in
            withAnimation {
                isAnimating = (newValue == .syncing)
            }
        }
    }
}

// Compact Sync Indicator (for toolbar)
struct SyncIndicator: View {
    @ObservedObject var monitor: SyncMonitor
    @State private var showDetails = false
    
    var body: some View {
        Button(action: {
            showDetails.toggle()
        }) {
            Image(systemName: monitor.status.icon)
                .foregroundStyle(monitor.status.color)
                .symbolEffect(.pulse, isActive: monitor.status == .syncing)
        }
        .popover(isPresented: $showDetails) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: monitor.status.icon)
                        .foregroundStyle(monitor.status.color)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud Sync")
                            .font(.headline)
                        Text(monitor.status.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let lastSync = monitor.lastSyncTime {
                    Divider()
                    Text("Last synced: \(lastSync.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if case .error(let message) = monitor.status {
                    Divider()
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                }
            }
            .padding()
            .frame(minWidth: 250)
        }
    }
}
