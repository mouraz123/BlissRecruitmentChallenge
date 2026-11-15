# Bliss Recruitment iOS Challenge

A native SwiftUI app implementing the ten-step Bliss iOS challenge.

## Requirements

- Xcode 15 or newer
- iOS 16 or newer (simulator or device)
- Internet access for the GitHub API

## Run

Open `BlissRecruitmentChallenge.xcodeproj` in Xcode, select the `BlissRecruitmentChallenge` scheme and an iOS simulator, then run the app. No third-party packages or API token are required.

## Build on a hosted Mac

The included [Codemagic configuration](./codemagic.yaml) builds the app for the iOS Simulator and saves the compiled `.app` as a build artifact. To use it, sign in at [Codemagic](https://codemagic.io/), connect the GitHub repository, and start the **iOS Simulator Build** workflow. Codemagic needs access to this repository to check out the source.

The included GitHub Actions workflow is an alternative and builds the app for the iOS Simulator on every push or pull request to `main` or `master`, when GitHub Actions is available on the account. To use it:

1. Create a **private** GitHub repository.
2. From this project directory, initialize and push the source:

   ```powershell
   git init -b main
   git add .
   git commit -m "Add Bliss Recruitment iOS challenge"
   git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
   git push -u origin main
   ```

3. Open the repository's **Actions** tab and check the **iOS Simulator Build** run. The compiled simulator `.app` is available as a workflow artifact.

The workflow compiles for the simulator; installing on a physical iPhone additionally requires Apple code signing and provisioning.

## Features

- Fetches GitHub's emoji map once and stores it in the app's Application Support directory. Random selection and the grid reuse that cache.
- Removes emojis from the current in-memory list only; pull to refresh restores the complete cached list.
- Searches GitHub users, downloads and persists each avatar image with its username, and uses saved records for repeat searches.
- Deletes saved avatars from persistent storage.
- Loads Apple's public repositories in pages of ten as the list is scrolled.
- Shows request, decoding, and persistence errors in the app.

## Implementation

The app uses SwiftUI, `URLSession`, Codable models, and small JSON files for local persistence. Avatar image bytes are persisted alongside the corresponding GitHub user record. The GitHub API's unauthenticated rate limit applies.
