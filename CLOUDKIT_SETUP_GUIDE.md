# CloudKit Sync Setup Guide

## What I've Configured

### ✅ Code Changes:
1. **Both apps** now use explicit CloudKit container: `iCloud.rens-corp.Pee-Pee-Tracker`
2. **Entitlements** include CloudKit and container identifiers
3. **Info.plist files** include `remote-notification` background mode
4. **Fallback handling** - apps will work locally if CloudKit fails

### 🔧 What You Need to Do in Xcode:

#### Step 1: Verify iCloud Capability
For **both** targets (Pee Tracker & Pee Tracker Watch App):

1. Select the target in Xcode
2. Go to **Signing & Capabilities** tab
3. Verify **iCloud** capability exists
4. Ensure **CloudKit** is checked
5. Verify container shows: `iCloud.rens-corp.Pee-Pee-Tracker`

#### Step 2: Verify Background Modes
For **both** targets:

1. In **Signing & Capabilities**
2. Check if **Background Modes** capability exists
3. If not, click **+ Capability** → Add **Background Modes**
4. Check **Remote notifications**

#### Step 3: Sign In with Apple ID
1. Go to **Xcode → Settings → Accounts**
2. Make sure you're signed in with an Apple ID
3. This Apple ID will be used for iCloud during testing

#### Step 4: Test on Real Devices
CloudKit sync works best on real devices (not simulators):
1. Test on actual iPhone and Apple Watch
2. Both devices must be signed in with the **same Apple ID**
3. iCloud must be enabled in Settings

## How to Test Sync

1. **Build and run both apps** on real devices
2. **On iPhone**: Start a session and complete it
3. **Wait 5-10 seconds** for sync to occur
4. **On Watch**: Pull to refresh or restart the app
5. The session should appear on Watch

## Troubleshooting

### If you see "CloudKit setup failed":
- ✅ Check you're signed in with Apple ID in Xcode
- ✅ Check iCloud is enabled on test devices
- ✅ Both devices use the same Apple ID
- ✅ Internet connection is working

### If sync doesn't work:
- ✅ Data will still save locally on each device
- ✅ Check console logs for CloudKit errors
- ✅ Wait 30-60 seconds - sync isn't instant
- ✅ Try restarting both apps

### CloudKit Container Not Found:
If the container `iCloud.rens-corp.Pee-Pee-Tracker` doesn't exist:
1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Sign in with your Apple Developer account
3. The container should be created automatically on first use
4. If not, you can create it manually

## Expected Console Messages

### Success:
```
✅ iPhone: ModelContainer initialized with CloudKit sync
📦 Container: iCloud.rens-corp.Pee-Pee-Tracker
```

### Fallback (will still work locally):
```
❌ Failed to initialize ModelContainer: [error details]
⚠️ Using local storage only (no sync)
```

## Notes

- **Sync is automatic** - no manual action needed
- **Changes sync in background** - may take 5-60 seconds
- **Works offline** - data syncs when connection restored
- **Both apps must use same container** for sync to work
