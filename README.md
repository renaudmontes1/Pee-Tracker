# Pee Tracker

A comprehensive iOS and watchOS app designed to help men monitor their urination patterns and symptoms through a structured pee diary.

## Features

### 🕰 Apple Watch App
The Watch app provides quick, friction-free logging:
- **One-tap Start/Stop**: Begin and end sessions with a single tap
- **Session Timer**: Real-time duration tracking with workout-style always-on display
- **Feeling Toggle**: Mark sessions as ✅ Positive or ❌ Negative
- **Comprehensive Symptom Tracking**: When negative, select from:
  - ⚡️ Pain/Discomfort
  - 🔥 Burning sensation
  - ⏸️ Difficulty starting
  - 💧 Weak stream/Dripping
  - 🚽 Incomplete emptying
  - ⏰ Frequent urges
  - 🩸 Blood present
- **2-Minute Reminder**: Gentle haptic reminder if session exceeds 2 minutes
- **History View**: Review past sessions directly on your wrist

### 📱 iPhone App
The iPhone app offers comprehensive tracking and analysis:

#### Logging Features
- All Watch functionality with expanded symptom tracking
- **Enhanced Symptom Selection**: Seven comprehensive urinary symptoms:
  - ⚡️ Pain/Discomfort - Any pain or discomfort during urination
  - 🔥 Burning sensation - Burning or stinging while urinating
  - ⏸️ Difficulty starting - Trouble initiating urine flow
  - 💧 Weak stream/Dripping - Weak, slow, or dripping stream
  - 🚽 Incomplete emptying - Feeling bladder isn't fully empty
  - ⏰ Frequent urges - Sudden, urgent need to urinate
  - 🩸 Blood present - Visible blood in urine (hematuria)
- **Session Notes**: Add freeform text for context (medications, activities, observations)
- **Manual Duration Entry**: Complete session details
- **Smart Badge Notifications**: App icon badge shows unread sessions synced from Watch

#### History & Review
- **Searchable History**: Find sessions by notes or symptoms
- **Filtering**: Filter by feeling (positive/negative)
- **Daily Grouping**: Sessions organized by date
- **Detailed View**: See complete session information
- **Swipe to Delete**: Easy data management

#### Analytics & Insights

**Charts & Visualizations:**
- Frequency trends (Day/Week/Month/3-Month/6-Month/Year views)
- Time-of-day distribution (with donut chart)
- Feeling distribution (positive vs negative)
- Symptom frequency analysis
- Trend indicators (comparing periods)

**Weekly Summary:**
- Average sessions per day
- Total sessions
- Nighttime frequency
- Negative session percentage
- Most common symptoms

**Health Insights:**
The app analyzes your data to detect:
- ⚠️ **Critical Issues**: Blood in urine, severe symptoms requiring immediate medical attention
- 🔴 **High Priority**: Recurring pain/burning, worsening symptoms, significant frequency changes
- 🟡 **Medium Priority**: Incomplete emptying patterns, difficulty starting, nocturia (nighttime urination)
- 🟢 **Positive Insights**: Healthy patterns, stable trends, low symptom frequency

Pattern Detection:
- Frequency changes over time (daily, weekly, monthly trends)
- Symptom severity and recurrence tracking
- Hydration pattern indicators
- Time-of-day clustering analysis
- Correlation with lifestyle changes
- Urgency pattern recognition

Health Recommendations:
- Hydration adjustments based on frequency
- Behavioral modifications for symptom management
- When to seek immediate medical attention
- Lifestyle tips based on detected patterns
- Pelvic floor health suggestions

#### Data Export
- **Doctor Visit Summary**: Generate comprehensive reports for medical consultations
- **CSV Export**: Raw data for spreadsheet analysis
- **PDF Reports**: Formatted summaries with insights
- **Customizable Periods**: Week, Month, or 3-Month exports
- **Share Functionality**: Email or share reports directly

### 🔒 Privacy & Security
- **Local-First Storage**: All data stored on your device
- **iCloud Sync**: End-to-end encrypted sync via CloudKit
- **No Third-Party Access**: Your data is never shared
- **Privacy-Focused Design**: Your data stays private and secure
- **Data Control**: Export and delete all data anytime

## Technical Details

### Architecture
- **SwiftUI**: Modern, declarative UI framework
- **SwiftData**: Persistent data storage with CloudKit integration
- **Swift Charts**: Native charting for beautiful visualizations
- **MVVM Pattern**: Clean separation of concerns

### Data Model
```swift
@Model
class PeeSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    var feeling: SessionFeeling
    var symptoms: [Symptom]
    var notes: String
}
```

### Analytics Engine
- Real-time pattern detection
- Statistical analysis
- Trend comparison across time periods
- Smart health insights generation

### Cross-Platform Sync
- Automatic CloudKit synchronization
- Seamless data sharing between iPhone and Apple Watch
- Conflict resolution
- Offline-first design

## Usage

### Getting Started
1. Launch the app on iPhone or Apple Watch
2. Tap "Start Session" when you begin urinating
3. Tap "Stop" when finished
4. Rate your feeling (Positive/Negative)
5. If negative, select any symptoms
6. (iPhone only) Add optional notes

### Viewing Insights
1. Open the iPhone app
2. Navigate to the "Insights" tab
3. Switch between "Charts" and "Health Insights"
4. Adjust timeframe to view different periods
5. Tap insights for detailed recommendations

### Exporting Data
1. Go to Settings tab
2. Tap "Export Data" or "Doctor Visit Summary"
3. Choose format (CSV or PDF) and period
4. Share via email, AirDrop, or copy to clipboard

## Health Disclaimer

⚠️ **Important**: This app is for informational and tracking purposes only and does not constitute medical advice. Always consult with a qualified healthcare professional for medical concerns, diagnosis, or treatment decisions.

The insights are based on general patterns and should not replace professional medical evaluation.

## Requirements

- iOS 17.0 or later
- watchOS 10.0 or later
- iCloud account (for sync between devices)

## Privacy Policy

- Data is stored locally and in your private iCloud account
- No analytics or tracking
- No third-party data sharing
- You control all data exports
- Can delete all data at any time

## Support

For questions or issues, contact support or visit the app's support page in Settings.

## Version

Current Version: 1.0.0

---

Built with ❤️ for better health tracking and awareness.
