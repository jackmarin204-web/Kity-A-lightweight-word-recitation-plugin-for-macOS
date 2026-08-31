# Kity

Kity is a tiny macOS menu-bar companion for Apple Notes. After you commit a Chinese word or phrase, it shows an English learning cue beside the caret.

## What it does

- Supports Apple Notes only.
- Keeps your existing Chinese input method unchanged.
- Uses Apple's on-device Chinese-to-English Translation framework for every cue.
- Does not bundle a dictionary, make network requests, modify notes, or record keystrokes.
- Reads at most 48 UTF-16 units immediately before the caret while Notes is frontmost; the text stays in memory only.

## Requirements

- macOS 26 or later
- Xcode 26 or later
- Apple Notes
- Accessibility permission for Kity
- Downloaded Simplified Chinese and English translation languages

## Download the offline translation languages

Open **System Settings → General → Language & Region → Translation Languages**, then download **Chinese (Simplified)** and **English**. The system models are managed by macOS; Kity does not include or upload them.

## Build

1. Open `NotesEnglishShadow.xcodeproj` in Xcode.
2. Select the app target, set a signing team and a unique bundle identifier.
3. Build and run.
4. Grant Accessibility permission in **System Settings → Privacy & Security → Accessibility**.

Or run tests from Terminal:

```sh
xcodebuild test -project NotesEnglishShadow.xcodeproj -scheme NotesEnglishShadow -destination 'platform=macOS'
```

## Privacy

Kity is active only while Notes is the frontmost app. It does not need Input Monitoring, Screen Recording, Automation, or network permission. Translation requests are handled by downloaded macOS language models.

## Publishing notes

Do not upload `xcode-derived/`, `DerivedData/`, signing certificates, profiles, or an ad-hoc signed `.app`. The included `.gitignore` excludes these artifacts.

## Attribution

The repository retains `LICENSES/LEXICON-NOTICE.md` and the optional legacy lexicon sources for attribution and reproducibility. The shipped pure-translation build does not bundle or query that lexicon.
