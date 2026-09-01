# Reliable Caret Observer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Kity update a word card from the current Apple Notes caret context rather than an unreliable commit delta, and render the supplied cat-food artwork correctly in the menu bar.

**Architecture:** `CaretWordDetector` extracts and identities the active Chinese candidate from `TextSnapshot.contextBeforeCaret`. `AppEnvironment` deduplicates identities, resolves a local word immediately, and uses the macOS translation model only for a current unresolved candidate. The AX session polls at 100ms as a fallback.

**Tech Stack:** Swift, AppKit, ApplicationServices accessibility APIs, macOS Translation framework, XCTest, `xcodebuild`, `codesign`.

---

### Task 1: Define and test a caret candidate detector

**Files:**
- Create: `NotesEnglishShadow/Learning/CaretWordDetector.swift`
- Create: `NotesEnglishShadowTests/CaretWordDetectorTests.swift`
- Modify: `NotesEnglishShadow.xcodeproj/project.pbxproj`

- [ ] Write failing tests: an end-of-context candidate returns `人工智能`; a Latin context returns `nil`; moving the caret yields a different identity.
- [ ] Run `xcodebuild test -project NotesEnglishShadow.xcodeproj -scheme NotesEnglishShadow -only-testing:NotesEnglishShadowTests/CaretWordDetectorTests`; expect failure because the detector does not exist.
- [ ] Implement `CaretCandidate(text:identity:)` and `CaretWordDetector.detect(contextBeforeCaret:caretLocation:)`. Use `HanText.lastHanRun`, retain at most 12 final Han characters, reject a candidate shorter than two characters, and include caret location plus context in the identity.
- [ ] Re-run the focused test target; expect PASS.
- [ ] Commit only the detector, test, and Xcode project registration as `feat: detect active Chinese caret candidate`.

### Task 2: Replace commit-delta routing with candidate routing

**Files:**
- Create: `NotesEnglishShadow/Learning/CaretCandidateRouter.swift`
- Create: `NotesEnglishShadowTests/CaretCandidateRouterTests.swift`
- Modify: `NotesEnglishShadow/App/AppEnvironment.swift:24-229`
- Modify: `NotesEnglishShadow/Accessibility/NotesSession.swift:216-232`
- Modify: `NotesEnglishShadow.xcodeproj/project.pbxproj`

- [ ] Write failing tests for `CaretCandidateRouter`: an unchanged context must return no second candidate; clearing context then typing `泥巴` again must return it again.
- [ ] Run `xcodebuild test -project NotesEnglishShadow.xcodeproj -scheme NotesEnglishShadow -only-testing:NotesEnglishShadowTests/CaretCandidateRouterTests`; expect failure because router does not exist.
- [ ] Implement a router that remembers only the last candidate identity and resets that memory when no candidate is present.
- [ ] In `AppEnvironment.probe`, replace `previousSnapshot` and `CommitResolver.resolve` with `candidateRouter.takeNewCandidate(context:caret:)`. On a local `WordResolver` match, cancel translation and immediately show the card. Otherwise translate only the current candidate and only display an asynchronous result whose request ID remains current. Locate the candidate from the end of `current.contextBeforeCaret` for its anchor.
- [ ] Set AX scheduling delay to 40ms and fallback polling to 100ms. Reset the router and cancel an outstanding translation in `resetTransientState`.
- [ ] Run `xcodebuild test -project NotesEnglishShadow.xcodeproj -scheme NotesEnglishShadow && xcodebuild build -project NotesEnglishShadow.xcodeproj -scheme NotesEnglishShadow -configuration Release`; expect all tests and the Release build to pass.
- [ ] Commit the routing files and modified source as `fix: observe Apple Notes caret context directly`.

### Task 3: Restore the colored menu-bar cat-food artwork

**Files:**
- Modify: `NotesEnglishShadow/UI/MenuBarController.swift:30-37`
- Modify: `NotesEnglishShadowTests/MenuBarControllerTests.swift`

- [ ] Add a testable icon configuration assertion that the image is non-template and 22×22 points.
- [ ] Run its focused test; expect failure because Kity currently uses a template image.
- [ ] Set the existing transparent `KityMenuBarCat` image to `isTemplate = false` and `NSSize(width: 22, height: 22)`. Do not regenerate the Finder `.icns` in this task.
- [ ] Run `xcodebuild test -project NotesEnglishShadow.xcodeproj -scheme NotesEnglishShadow`; expect PASS.
- [ ] Commit only the menu implementation and its test as `fix: render Kity menu icon in color`.

### Task 4: Install and clean obsolete Kity artifacts

**Files:**
- Modify: `/Applications/Kity.app` (replace only after verified build)
- Remove: exact, inspected Kity-only old build products and dated Kity app backups

- [ ] Enumerate candidate cleanup targets in the Trash and the project’s derived build directories. Do not include `/Applications/Kity.app`, project sources, tests, icons, dictionaries, Git history, or user Notes data.
- [ ] Build the Release bundle, sign it as `NotesEnglishShadow Local Code Signing Identity`, and verify it using `codesign --verify --deep --strict --verbose=2`.
- [ ] Move the current `/Applications/Kity.app` to Trash as a recoverable backup and copy in the verified bundle.
- [ ] Remove only the exact obsolete Kity/NotesEnglishShadow artifacts enumerated earlier, preserving the installed app.
- [ ] Launch Kity and manually verify in Apple Notes: `人工智能泥巴`, delete and retype `泥巴`, then type `尼加拉瓜`. Each new candidate must update the left-side card quickly, a retyped word must display again, and the menu bar must show a colored cat-food image rather than a black block.
