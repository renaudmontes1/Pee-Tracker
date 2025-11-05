# Target Membership Guide - Pee Tracker Project

## Overview
This document explains which files need to be included in each target (iPhone app vs Watch app) for the project to build and sync correctly.

---

## 📱 **iPhone Target: "Pee Tracker"**

### Required Files (iPhone ONLY)

#### **App Entry Point**
- `Pee Tracker/Pee_TrackerApp.swift` - iPhone app entry point
- `Pee Tracker/ContentView.swift` - Main iPhone tab view

#### **iPhone-Specific Views**
- `Pee Tracker/Views/LoggingView.swift` - iPhone logging interface
- `Pee Tracker/Views/HistoryView.swift` - iPhone history view (full-featured)
- `Pee Tracker/Views/InsightsView.swift` - Charts and analytics (iPhone only)
- `Pee Tracker/Views/HealthInsightsView.swift` - AI insights view (iPhone only)
- `Pee Tracker/Views/SettingsView.swift` - Settings and export (iPhone only)

#### **Analytics (iPhone ONLY)**
- `Pee Tracker/Analytics/AnalyticsEngine.swift` - Statistical calculations
- `Pee Tracker/Analytics/HealthInsightsEngine.swift` - Pattern detection

#### **Assets & Configuration**
- `Pee Tracker/Assets.xcassets/` - iPhone app icons and assets
- `Pee Tracker/Pee Tracker.entitlements` - iPhone capabilities

---

## ⌚ **Watch Target: "Pee Tracker Watch App"**

### Required Files (Watch ONLY)

#### **App Entry Point**
- `Pee Tracker Watch App/Pee_TrackerApp.swift` - Watch app entry point
- `Pee Tracker Watch App/ContentView.swift` - Watch main view with tabs

#### **Watch-Specific Views**
- `Pee Tracker Watch App/Views/HistoryView.swift` - Watch history view (compact)
- `Pee Tracker Watch App/Views/SyncDebugView.swift` - Sync diagnostics

#### **Assets & Configuration**
- `Pee Tracker Watch App/Assets.xcassets/` - Watch app icons and assets
- `Pee Tracker Watch App/Pee Tracker Watch App.entitlements` - Watch capabilities

---

## 🔄 **SHARED Files (BOTH Targets)**

### **Critical: These MUST be in BOTH targets**

#### **Data Models**
✅ `Pee Tracker/Models/PeeSession.swift`
   - Core SwiftData model
   - Defines session structure
   - **MUST** be identical across both apps

✅ `Pee Tracker/Models/SessionStore.swift`
   - Session lifecycle management
   - Save/delete operations
   - **MUST** be shared for consistent behavior

✅ `Pee Tracker/Models/SyncMonitor.swift`
   - CloudKit sync monitoring
   - Platform-aware logging
   - **MUST** be shared for sync status

✅ `Pee Tracker/Models/SubscriptionManager.swift`
   - CloudKit notification subscriptions
   - Push notification handling
   - **MUST** be shared for bidirectional notifications

---

## 📋 **How to Set Target Membership in Xcode**

### For Shared Files:

1. **Select the file** in Xcode's Project Navigator
2. Open the **File Inspector** (right panel, first tab)
3. Under **Target Membership**, check BOTH:
   - ✅ Pee Tracker
   - ✅ Pee Tracker Watch App

### For Platform-Specific Files:

1. **Select the file** in Xcode's Project Navigator
2. Open the **File Inspector**
3. Under **Target Membership**, check ONLY the appropriate target:
   - iPhone views → ✅ Pee Tracker only
   - Watch views → ✅ Pee Tracker Watch App only

---

## ⚠️ **Common Mistakes to Avoid**

### ❌ **DON'T:**
- Add Analytics files to Watch target (watchOS doesn't support all APIs)
- Add Settings/Export views to Watch (uses UIKit APIs not available on watchOS)
- Add iPhone-specific UI to Watch target
- Duplicate model files - always share them

### ✅ **DO:**
- Keep all model files in `Pee Tracker/Models/` and share them
- Use platform checks (`#if os(watchOS)`) for platform-specific code
- Ensure both targets reference the SAME model files (not copies)
- Verify shared container identifier matches in both apps

---

## 🔍 **Verification Checklist**

### After Setting Up Target Membership:

#### ✅ **Check Shared Models:**
```bash
# All these should be in BOTH targets:
Pee Tracker/Models/PeeSession.swift
Pee Tracker/Models/SessionStore.swift
Pee Tracker/Models/SyncMonitor.swift
Pee Tracker/Models/SubscriptionManager.swift
```

#### ✅ **Check Platform-Specific:**
```bash
# iPhone ONLY:
Pee Tracker/Analytics/*
Pee Tracker/Views/* (except shared ones)

# Watch ONLY:
Pee Tracker Watch App/Views/*
Pee Tracker Watch App/ContentView.swift
```

#### ✅ **Build Both Targets:**
```bash
# iPhone
xcodebuild -scheme "Pee Tracker" -sdk iphonesimulator

# Watch
xcodebuild -scheme "Pee Tracker Watch App" -sdk watchsimulator
```

Both should build successfully with no missing symbols.

---

## 🏗️ **Project Structure Summary**

```
Pee Tracker/
├── Models/                          [SHARED - Both Targets]
│   ├── PeeSession.swift            ✅ iPhone ✅ Watch
│   ├── SessionStore.swift          ✅ iPhone ✅ Watch
│   ├── SyncMonitor.swift           ✅ iPhone ✅ Watch
│   └── SubscriptionManager.swift   ✅ iPhone ✅ Watch
│
├── Analytics/                       [iPhone ONLY]
│   ├── AnalyticsEngine.swift       ✅ iPhone ❌ Watch
│   └── HealthInsightsEngine.swift  ✅ iPhone ❌ Watch
│
├── Views/                           [iPhone ONLY]
│   ├── LoggingView.swift           ✅ iPhone ❌ Watch
│   ├── HistoryView.swift           ✅ iPhone ❌ Watch
│   ├── InsightsView.swift          ✅ iPhone ❌ Watch
│   ├── HealthInsightsView.swift    ✅ iPhone ❌ Watch
│   └── SettingsView.swift          ✅ iPhone ❌ Watch
│
├── ContentView.swift                ✅ iPhone ❌ Watch
├── Pee_TrackerApp.swift             ✅ iPhone ❌ Watch
└── Assets.xcassets/                 ✅ iPhone ❌ Watch

Pee Tracker Watch App/
├── Views/                           [Watch ONLY]
│   ├── HistoryView.swift           ❌ iPhone ✅ Watch
│   └── SyncDebugView.swift         ❌ iPhone ✅ Watch
│
├── ContentView.swift                ❌ iPhone ✅ Watch
├── Pee_TrackerApp.swift             ❌ iPhone ✅ Watch
└── Assets.xcassets/                 ❌ iPhone ✅ Watch
```

---

## 🎯 **Key Principles**

1. **Share Data Layer**: All models and data management code should be shared
2. **Separate UI Layer**: Views are platform-specific due to API differences
3. **Single Source of Truth**: Never duplicate model files - always reference the same file
4. **Platform Checks**: Use `#if os(watchOS)` for any platform-specific code in shared files
5. **Same Container**: Both apps must use identical CloudKit container identifier

---

## 🔧 **Troubleshooting**

### "Symbol not found" errors:
- **Cause**: File is not in the correct target
- **Fix**: Add file to the missing target via File Inspector

### "Duplicate symbol" warnings:
- **Cause**: Same file added to target twice
- **Fix**: Remove duplicate from target membership

### Sync not working:
- **Cause**: Models not shared or different versions
- **Fix**: Ensure all model files are in BOTH targets and not duplicated

### Build fails with "unavailable API":
- **Cause**: iPhone-only API used in Watch target
- **Fix**: Move platform-specific code to appropriate target or add platform checks

---

## 📝 **Notes**

- The `Pee Tracker Watch App/Models/` folder is intentionally **empty**
- Watch app references models from `Pee Tracker/Models/` via target membership
- This ensures both apps always use the same data model
- CloudKit sync requires identical schemas across devices
- Any changes to models automatically apply to both targets
