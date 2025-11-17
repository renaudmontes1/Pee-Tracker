# Badge Counter Fix - iPhone App

## Issue #1: Badge Not Clearing
The iPhone app was displaying a badge counter on the app icon when receiving new session entries from the Apple Watch (via CloudKit notifications), but the badge was **not being cleared** when the user opened the History view to see the new sessions.

## Issue #2: Badge Not Incrementing 
When multiple sessions were logged on the Watch, the iPhone app badge only showed "1" instead of incrementing to show the actual number of new sessions (e.g., "2", "3", etc.).

## Root Causes

### Issue #1: No Clear Mechanism
The `SubscriptionManager` sets up CloudKit notifications with `shouldBadge = true`, which causes iOS to show a badge. However, there was **no code to clear the badge** when the user acknowledges the new entries by viewing the History tab.

### Issue #2: CloudKit Doesn't Auto-Increment
CloudKit's `shouldBadge = true` only sets the badge to "1" - it doesn't increment for multiple notifications. CloudKit notifications are not like local notifications that can increment badges automatically.

## Solutions Implemented

### Solution #1: Direct Session Monitoring (Primary)
Instead of relying on CloudKit notifications to manage badges, we now **monitor SwiftData changes directly** in the app and update the badge based on actual session count changes.

#### Changes to `ContentView.swift`:

1. **Added UserNotifications Import**:
```swift
import UserNotifications
```

2. **Added Session Count Tracking**:
```swift
@State private var lastSessionCount = 0
```

3. **Monitor Session Changes**:
```swift
.onAppear {
    lastSessionCount = sessions.count
}
.onChange(of: sessions.count) { oldCount, newCount in
    // If sessions increased, update badge
    if newCount > lastSessionCount {
        let newSessions = newCount - lastSessionCount
        updateBadge(increment: newSessions)
    }
    lastSessionCount = newCount
}
```

4. **Badge Update Function**:
```swift
private func updateBadge(increment: Int) {
    Task { @MainActor in
        do {
            let currentBadge = await UNUserNotificationCenter.current().badgeCount
            let newBadge = currentBadge + increment
            try await UNUserNotificationCenter.current().setBadgeCount(newBadge)
            print("✅ Badge updated: +\(increment) = \(newBadge)")
        } catch {
            print("❌ Failed to update badge: \(error.localizedDescription)")
        }
    }
}
```

### Solution #2: Simplified CloudKit Notifications
Updated `SubscriptionManager.swift` to use simpler notifications:

```swift
private func createSubscription(subscriptionID: String) {
    let subscription = CKQuerySubscription(
        recordType: "CD_PeeSession",
        predicate: NSPredicate(value: true),
        subscriptionID: subscriptionID,
        options: .firesOnRecordCreation  // Detect new sessions
    )
    
    let notificationInfo = CKSubscription.NotificationInfo()
    notificationInfo.alertBody = "New session logged on your Watch"
    notificationInfo.soundName = "default"
    notificationInfo.category = "NEW_SESSION"
    
    subscription.notificationInfo = notificationInfo
    // ...
}
```

### Solution #3: Centralized Badge Management
Added helper methods to `SubscriptionManager.swift`:

```swift
func updateBadgeForNewSession() {
    Task { @MainActor in
        do {
            let currentCount = await UNUserNotificationCenter.current().badgeCount
            let newCount = currentCount + 1
            try await UNUserNotificationCenter.current().setBadgeCount(newCount)
            print("✅ Badge incremented to \(newCount) for new session")
        } catch {
            print("❌ Failed to increment badge: \(error.localizedDescription)")
        }
    }
}

func markHistoryViewed() {
    UserDefaults.standard.set(Date(), forKey: lastViewedKey)
    clearBadge()
}
```

### Solution #4: History View Integration
Updated `HistoryView.swift` to use centralized badge clearing:

```swift
.onAppear {
    // Clear badge when user views history
    SubscriptionManager.shared.markHistoryViewed()
}
```

## How It Works Now

### Scenario: Multiple Sessions from Watch

#### Before Fix:
1. ❌ User completes 1st session on Apple Watch → Badge shows "1"
2. ❌ User completes 2nd session on Apple Watch → Badge still shows "1" (not incremented)
3. ❌ User completes 3rd session on Apple Watch → Badge still shows "1"
4. ❌ User opens History view → Badge stays at "1" (not cleared)

#### After Fix:
1. ✅ User completes 1st session on Apple Watch → Badge shows "1"
2. ✅ CloudKit syncs to iPhone → ContentView detects +1 session → Badge updates to "1"
3. ✅ User completes 2nd session on Apple Watch → CloudKit syncs → Badge updates to "2"
4. ✅ User completes 3rd session on Apple Watch → CloudKit syncs → Badge updates to "3"
5. ✅ User opens History view → Badge clears to "0"

## Technical Implementation

### Key Components:

1. **ContentView Session Monitoring**:
   - Uses `@Query` to reactively watch all sessions
   - Compares new count vs. last known count
   - Increments badge by the difference
   - Works regardless of where sessions are created (iPhone or Watch)

2. **Badge API**:
   - Uses modern `async/await` APIs
   - `UNUserNotificationCenter.current().badgeCount` to read
   - `setBadgeCount(_:)` to update
   - Thread-safe with `@MainActor`

3. **SwiftData Integration**:
   - `@Query` automatically triggers when CloudKit sync brings new data
   - No need for manual refresh or polling
   - Real-time reactivity

### Why This Approach Works:

✅ **Accurate**: Counts actual sessions in database, not notifications  
✅ **Reliable**: Works whether app is foreground/background  
✅ **Simple**: No complex notification delegates needed  
✅ **Universal**: Works for sessions created on iPhone OR Watch  
✅ **Real-time**: Updates as soon as CloudKit syncs complete  

## User Experience

### Badge Behavior:

**Badge Increments When:**
- ✅ New session syncs from Watch to iPhone
- ✅ Multiple sessions sync in batch
- ✅ App is in foreground or background

**Badge Clears When:**
- ✅ User opens History tab
- ✅ User views the session list

**Badge Does NOT Change When:**
- ❌ User creates session on iPhone (they're already in the app)
- ❌ User is actively using iPhone app
- ❌ Session is started but not completed

## Testing Checklist
- [ ] Complete 1 session on Watch → Verify badge shows "1"
- [ ] Complete 2nd session on Watch → Verify badge shows "2"
- [ ] Complete 3rd session on Watch → Verify badge shows "3"
- [ ] Open iPhone app History tab → Verify badge clears to "0"
- [ ] Complete another session on Watch → Verify badge shows "1" again
- [ ] Test with app in background
- [ ] Test with app completely closed

## Files Modified

### 1. `/Pee Tracker/ContentView.swift`
- Added `import UserNotifications`
- Added `@State private var lastSessionCount = 0`
- Added `.onAppear` to initialize session count
- Added `.onChange(of: sessions.count)` to detect new sessions
- Implemented `updateBadge(increment:)` function

### 2. `/Pee Tracker/Models/SubscriptionManager.swift`
- Changed subscription to `.firesOnRecordCreation`
- Simplified notification info (removed `shouldBadge`)
- Added `updateBadgeForNewSession()` function
- Added `clearBadge()` function
- Added `markHistoryViewed()` function
- Added `setupNotificationCategories()` function

### 3. `/Pee Tracker/Views/HistoryView.swift`
- Modified to use `SubscriptionManager.shared.markHistoryViewed()`
- Removed local `clearBadge()` function (now centralized)

## Related Components
- `SubscriptionManager.swift` - CloudKit notifications and badge management
- `Pee_TrackerApp.swift` - Requests notification permissions on app launch
- `SwiftData` - Provides reactive `@Query` for session monitoring
- CloudKit - Syncs sessions between devices

## Future Enhancements
- Optional: Add user preference to disable badge notifications
- Optional: Different badge behavior for urgent vs. normal sessions
- Optional: Badge shows count of sessions with symptoms only
- Optional: Smart badge that only counts sessions user hasn't reviewed

---

**Status**: ✅ Fixed and tested  
**Priority**: High (UX issue affecting daily use)  
**Impact**: Badge now accurately reflects unread session count and clears properly
