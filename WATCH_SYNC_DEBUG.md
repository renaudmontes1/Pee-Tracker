# Apple Watch Sync Debugging Guide

## Overview
The Watch app now includes a comprehensive sync debugging panel to help troubleshoot CloudKit synchronization issues.

## Accessing the Debug Panel

1. **Open the Watch App**: Launch "Pee Pee Tracker" on your Apple Watch
2. **Tap the Gear Icon**: Look for the settings gear icon in the top-left corner
3. **View Sync Diagnostics**: The debug panel will open with comprehensive sync information

## What You'll See

### 1. Container ID
- Shows the exact CloudKit container identifier being used
- Should display: `iCloud.rens-corp.Pee-Pee-Tracker`
- This confirms which iCloud container the app is attempting to sync with

### 2. iCloud Account Status
Displays your iCloud account status with color-coded indicators:
- ✅ **Available** (Green): iCloud is properly configured and ready
- ❌ **No Account** (Red): No iCloud account is signed in
- ⚠️ **Restricted** (Red): iCloud Drive is disabled in Settings
- ❓ **Could Not Determine** (Orange): Temporary check failure

### 3. Sync Status
Real-time sync status with visual indicators:
- ⚪ **Idle** (Gray): No active sync operation
- 🔵 **Syncing...** (Blue): Currently uploading/downloading data
- ✅ **Success** (Green): Last sync completed successfully
- ❌ **Error** (Red): Sync failed with error message

### 4. Recent Activity Log
Chronological log of the last 50 sync events, showing:
- Timestamp of each event
- Event type (info/success/error/warning)
- Descriptive message
- Color-coded icons for quick visual scanning

## Troubleshooting Common Issues

### Watch Not Syncing to iPhone

**Check These Items:**

1. **iCloud Account Status**
   - Verify shows "Available" (green checkmark)
   - If "No Account": Sign into iCloud on your Watch via the iPhone Watch app
   - If "Restricted": Enable iCloud Drive in iPhone Settings > [Your Name] > iCloud

2. **Container ID Matches**
   - Both Watch and iPhone must use the same container ID
   - Should be: `iCloud.rens-corp.Pee-Pee-Tracker`

3. **Recent Activity Log**
   - Look for "Sync started" followed by "Sync completed successfully"
   - If you see errors, note the exact error message
   - Common errors:
     - "Network unavailable": Check WiFi/Cellular connection
     - "Account not available": Sign into iCloud
     - "Quota exceeded": Free up iCloud storage

4. **Manual Sync Test**
   - Start a session on Watch
   - Complete the session with feeling/symptoms
   - Check the Recent Activity log immediately
   - You should see: "Sync started" → "Sync completed successfully"
   - Switch to iPhone and check History tab for the session

### Understanding Sync Timing

CloudKit sync happens **automatically in the background**:
- **When**: After saving a session, usually within 5-30 seconds
- **Network**: Requires WiFi or cellular data
- **Battery**: May be delayed if Watch is in low power mode
- **Background**: Sync continues even when app is closed

### What to Look For

**Healthy Sync Pattern:**
```
✓ Sync monitor initialized
✓ Monitoring started
ℹ️ Sync started
✓ Sync completed successfully
```

**Problem Sync Pattern:**
```
✓ Sync monitor initialized
✓ Monitoring started
ℹ️ Sync started
❌ Sync error: [error details]
```

## Sync Flow Diagram

```
Watch App                     CloudKit                    iPhone App
    |                            |                             |
    | 1. Save session            |                             |
    |--------------------------->|                             |
    |                            |                             |
    | 2. "Sync started" log      |                             |
    |                            |                             |
    |    3. Upload to cloud      |                             |
    |--------------------------->|                             |
    |                            |                             |
    |    "Sync completed"        | 4. Push notification        |
    |<---------------------------|--------------------------->|
    |                            |                             |
    |                            | 5. Download from cloud      |
    |                            |<----------------------------|
    |                            |                             |
    |                            |    Session appears in       |
    |                            |    History tab              |
    |                            |                             |
```

## Tips for Successful Sync

1. **Keep Both Devices Connected**
   - Watch needs WiFi or cellular
   - iPhone should be on WiFi or cellular
   - Bluetooth connection alone is not enough for CloudKit

2. **Give It Time**
   - Initial sync can take 15-30 seconds
   - Don't force quit the app immediately after saving
   - Background sync will continue even if you switch apps

3. **Check the Logs**
   - The Recent Activity log shows exactly what's happening
   - Success = green checkmark
   - Errors will be in red with specific messages

4. **Refresh Status**
   - Tap "Refresh Status" button at bottom of debug panel
   - This re-checks iCloud account status
   - Useful after changing iCloud settings

## When to Report Issues

If you consistently see sync errors, note:
1. The exact error message from Recent Activity log
2. Your iCloud Account status
3. Whether the issue happens on Watch-to-iPhone, iPhone-to-Watch, or both
4. Network conditions (WiFi/cellular/offline)

The debug panel gives you all the information needed to diagnose CloudKit sync issues!
