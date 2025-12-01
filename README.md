# JobSwipe AI

JobSwipe AI is an iOS 17 SwiftUI app that lets candidates swipe through curated job cards, save a profile and resumé with SwiftData, and toggle between mock and live job feeds.

## Features
- Swipeable deck with Apply/Pass gestures, undo, and badges for predicted actions in `FeedView`.
- Personalized searches built from the saved `UserProfile` (titles, locations, job types) and optional remote search keywords.
- Profile workspace for contact info, preferences, and resumé storage (`ProfileView`), backed by SwiftData models (`UserProfile`, `ResumeDocument`, `JobApplication`).
- Settings to switch between the mock dataset and live Adzuna data, plus quick search-term tweaks.
- Mock dataset (`Resources/MockData/mock_jobs.json`) for offline/demo use; graceful fallback when no API keys are present.

## Requirements
- Xcode 15 or newer
- iOS 17+ (SwiftData)
- Swift 5.9+

## Project Structure
- `App/` – Entry point, environment wiring, and tab layout (`JobSwipeAIApp`, `AppEnvironment`, `RootTabView`).
- `Features/Feed/` – Swipe deck UI and logic (`FeedView`, `FeedViewModel`, `FeedJobCardView`).
- `Features/Profile/` – Profile/resumé editor and persistence.
- `Features/Settings/` – Toggles for data source and search term.
- `JobAPI/` – `JobAPI` protocol plus implementations (`MockJobAPI`, `AdzunaJobAPI`, `RemotiveJobAPI`).
- `Networking/` – Lightweight `HTTPClient` abstraction with `URLSessionHTTPClient`.
- `Models/` – Shared domain models (jobs, applications, salary, enums).
- `Persistence/` – `ModelContainerProvider` configuring the SwiftData schema.
- `Resources/MockData/` – Local mock job feed.

## Running the app (mock feed)
1) Open `JobSwipeAI.xcodeproj` in Xcode.  
2) Select the `JobSwipeAI` scheme and run on an iOS 17 simulator or device.  
3) The app defaults to `MockJobAPI`; you can swipe through the bundled dataset immediately.

## Using live Adzuna data
1) Get Adzuna API credentials (App ID and App Key).  
2) In `JobSwipeAI/JobSwipeAI/JobAPI/AdzunaJobAPI.swift`, update `AdzunaJobAPIConfiguration.default` with your `appID` and `appKey`. You can also adjust `defaultSearchTerm`, `defaultLocation`, or `resultsPerPage`.  
3) Run the app and open **Settings**. Turn off “Use mock job feed” and optionally set “Remote search keywords.” The feed will use Adzuna when keys are present; if keys are missing, it automatically falls back to the mock dataset.

## How matching works
- `FeedView` asks `FeedViewModel` to load jobs for the first saved `UserProfile`.  
- The active `JobAPI` comes from `AppEnvironment` (mock vs Adzuna). Search terms and locations are derived from profile preferences, with the remote search term override from Settings.  
- Swipes update local state with a history stack so the last action can be undone.

## Data and persistence
- SwiftData stores profiles, resumés, and application records via `ModelContainerProvider.shared()` (see `Persistence/ModelContainerProvider.swift`).  
- Resume text is kept locally in `ResumeDocument`; nothing is uploaded by default.  
- Job applications currently store status and generated artifacts locally; remote submission stubs simply return canned responses.

## Notes and next steps
- `Features/Applications/ApplicationsView.swift` is a placeholder for richer tracking.  
- `JobAPI/RemotiveJobAPI.swift` exists but is not yet wired into `AppEnvironment`.  
- No automated tests are present yet; run-and-tap is the primary verification path.  
- Avoid committing real API keys. Consider a local config approach (e.g., Swift package secrets) if distributing builds.
