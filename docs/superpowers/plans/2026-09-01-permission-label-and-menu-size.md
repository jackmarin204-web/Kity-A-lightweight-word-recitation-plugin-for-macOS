# Permission Label and Menu Size Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the cached old accessibility label and render Kity’s menu icon at 20pt.

**Architecture:** Reset only the TCC Accessibility permission for Kity’s existing bundle identifier, then allow the current Kity bundle metadata to be registered on reauthorization. Keep the icon colored and change only its point size.

**Tech Stack:** Swift/AppKit, XCTest, `tccutil`, `xcodebuild`, `codesign`.

---

### Task 1: Change and test icon size

**Files:**
- Modify: `NotesEnglishShadow/UI/MenuBarController.swift`
- Modify: `NotesEnglishShadowTests/MenuBarControllerTests.swift`
- Modify: `NotesEnglishShadowTests/LexiconStoreTests.swift`

- [ ] Change the test expectations from `NSSize(width: 22, height: 22)` to `NSSize(width: 20, height: 20)` while retaining `isTemplate == false`.
- [ ] Run the focused menu test and observe failure.
- [ ] Set `MenuBarIconConfiguration.default.size` to `NSSize(width: 20, height: 20)`.
- [ ] Run the full test suite; expect PASS.

### Task 2: Install and reset cached authorization

**Files:**
- Modify: `/Applications/Kity.app` by replacement only after build and signature verification

- [ ] Build Release, sign with `NotesEnglishShadow Local Code Signing Identity`, and verify it.
- [ ] Move the prior installed app to Trash, install the verified app, then verify the installed signature.
- [ ] Run `tccutil reset Accessibility org.xiaozhu.NotesEnglishShadow` to remove only Kity’s cached Accessibility permission record.
- [ ] Delete the just-created old app backup after installation succeeds; launch Kity.
- [ ] Verify current app metadata remains Kity and tell the user to re-enable Kity in System Settings > Privacy & Security > Accessibility.
