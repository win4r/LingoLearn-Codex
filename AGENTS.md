# Repository Guidelines

## Project Structure & Module Organization
- `LingoLearn/` contains the SwiftUI app source (entry in `LingoLearn/LingoLearnApp.swift`, primary UI in `LingoLearn/ContentView.swift`).
- `LingoLearn/Assets.xcassets/` holds app icons and color assets.
- `LingoLearnTests/` contains unit tests using the Swift Testing framework.
- `LingoLearnUITests/` contains UI tests using XCTest.
- `LingoLearn.xcodeproj/` is the Xcode project configuration.

## Build, Test, and Development Commands
- Open the project in Xcode: `open LingoLearn.xcodeproj`.
- Build from CLI: `xcodebuild -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 15' build`.
- Run all tests: `xcodebuild test -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 15'`.
- Run unit tests only: `xcodebuild test -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing LingoLearnTests`.
- Run UI tests only: `xcodebuild test -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing LingoLearnUITests`.

## Coding Style & Naming Conventions
- Use 4-space indentation and standard Swift formatting (Xcode formatter is sufficient).
- Types and protocols use UpperCamelCase (e.g., `ContentView`); functions and variables use lowerCamelCase (e.g., `testLaunch`).
- Keep SwiftUI views small and composable; prefer `View` structs per feature screen.

## Testing Guidelines
- Unit tests live in `LingoLearnTests/` and use `@Test` with `#expect(...)`.
- UI tests live in `LingoLearnUITests/` and use XCTest `test...` methods.
- Name tests to describe behavior (e.g., `testLaunchPerformance`, `testStudyFlowStartsAtHome`).

## Commit & Pull Request Guidelines
- This checkout does not include Git history, so no existing commit convention is visible.
- Use short, imperative commit summaries (e.g., `Add flashcard session view`).
- PRs should include a clear description, linked issue (if any), and screenshots for UI changes.

## Configuration & Assets
- Keep app secrets and environment-specific values out of the project files.
- Add new images or colors under `LingoLearn/Assets.xcassets/` and reference them by asset name in SwiftUI.
