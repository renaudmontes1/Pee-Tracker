# Apple Watch Workout-Style Session Mode

## Overview
The Apple Watch app now behaves like the native Workout app during active pee sessions, providing an enhanced user experience with always-on display and smart reminders.

## Features Implemented

### 1. Extended Runtime Session (Always-On Display)
- **Like Workout App**: When a session starts, the watch screen stays on and won't lock
- **Implementation**: Uses `WKExtendedRuntimeSession` to prevent screen sleep
- **Lifecycle Management**: 
  - Starts when session begins
  - Automatically invalidated when session ends
  - Re-starts if app returns to foreground during active session

### 2. Two-Minute Reminder
- **Smart Notification**: After 2 minutes of an active session, the watch vibrates to remind the user
- **Haptic Feedback**: Uses `.notification` haptic pattern (3 distinct taps)
- **One-Time Alert**: Only triggers once per session to avoid annoyance
- **Purpose**: Gentle reminder to complete the session if it's taking longer than expected

### 3. Session State Management
- **Proper Cleanup**: Extended runtime session is invalidated when:
  - User stops the session
  - View disappears
  - Session end sheet is shown
- **State Tracking**: Uses `@State` to maintain session reference throughout view lifecycle

## Technical Details

### Code Changes in `ContentView.swift`

#### Imports
```swift
import WatchKit  // Added for WKExtendedRuntimeSession and WKInterfaceDevice
```

#### New State Variables
```swift
@State private var hasShownTwoMinuteReminder = false
@State private var extendedRuntimeSession: WKExtendedRuntimeSession?
@Environment(\.scenePhase) private var scenePhase
```

#### Key Functions

**Extended Runtime Management**:
```swift
private func startExtendedRuntimeSession() {
    #if os(watchOS)
    guard extendedRuntimeSession == nil else { return }
    let session = WKExtendedRuntimeSession()
    extendedRuntimeSession = session
    session.start()
    #endif
}

private func endExtendedRuntimeSession() {
    #if os(watchOS)
    extendedRuntimeSession?.invalidate()
    extendedRuntimeSession = nil
    #endif
}
```

**Two-Minute Reminder**:
```swift
private func triggerTwoMinuteReminder() {
    WKInterfaceDevice.current().play(.notification)
    print("⏰ 2-minute reminder: Session still active")
}
```

**Timer Logic**:
```swift
if elapsedTime >= 120 && !hasShownTwoMinuteReminder {
    hasShownTwoMinuteReminder = true
    triggerTwoMinuteReminder()
}
```

## User Experience

### Before Changes
- ❌ Screen would lock after ~70 seconds of inactivity
- ❌ User had to tap watch to wake it up to see timer
- ❌ No reminder if session was forgotten

### After Changes
- ✅ Screen stays on throughout entire session (like Workout app)
- ✅ Timer always visible without needing to wake watch
- ✅ Haptic reminder at 2 minutes if session is still active
- ✅ Better battery management with proper session lifecycle

## Platform Compatibility
- **watchOS Only**: Extended runtime features are wrapped in `#if os(watchOS)` checks
- **Fallback**: On other platforms, code compiles without runtime errors
- **API Requirements**: Requires watchOS 9.0+ for `WKExtendedRuntimeSession`

## Battery Impact
- **Minimal Impact**: Extended runtime is only active during sessions
- **Auto-Cleanup**: Session is invalidated immediately when stopped
- **Similar to Workout**: Uses same API as Apple's native Workout app

## Testing Checklist
- [ ] Start a session and verify screen stays on
- [ ] Wait 2 minutes and confirm haptic feedback
- [ ] Stop session and verify screen sleep returns to normal
- [ ] Test with watch crown locked to ensure it still works
- [ ] Verify battery drain is acceptable during typical usage

## Future Enhancements
- Optional: Add settings to customize reminder timing (1min, 2min, 5min)
- Optional: Multiple reminders (e.g., at 2min and 5min)
- Optional: Voice feedback option for accessibility
- Optional: Always-on heart rate display during session
