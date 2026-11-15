# Bliss Recruitment iOS Challenge

A native SwiftUI implementation of the Bliss Applications iOS challenge.

## Run locally

Open `BlissRecruitmentChallenge.xcodeproj` in Xcode, select the `BlissRecruitmentChallenge` scheme and an iOS Simulator, then run the app. The project requires Xcode 15 or newer, targets iOS 16 or newer, and uses no third-party packages or API token. Internet access is required for GitHub API requests.

## Build with Codemagic

The [`codemagic.yaml`](./codemagic.yaml) workflow builds the app for the iOS Simulator and publishes the `.app` as an artifact. Connect this GitHub repository to [Codemagic](https://codemagic.io/) and start the **iOS Simulator Build** workflow.

The simulator build is not signed for installation on a physical iPhone. Device installation requires Apple code signing and provisioning.

## Challenge features

- Fetches GitHub's emoji map once and stores it in the app's Application Support directory. Random selection and the emoji grid reuse the cached data.
- Removes emojis from the visible list only; pull-to-refresh restores all cached emojis.
- Searches GitHub users, downloads and persists avatar images, and uses saved records for repeat searches.
- Lists saved avatars and deletes selected records from persistent storage.
- Loads Apple's public repositories in pages of ten as the list is scrolled.
- Presents API, decoding, and persistence errors in the app.

The app uses SwiftUI, `URLSession`, Codable models, and JSON files for local persistence. GitHub's unauthenticated API rate limit applies.
