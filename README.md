# Notes English Shadow

A small, offline macOS menu-bar app that shows one English cue after a known Chinese phrase is committed in Apple Notes.

## Requirements and build

- macOS 14 or later
- Xcode 15 or later
- Apple Notes (`com.apple.Notes`) as the only supported editor

Open `NotesEnglishShadow.xcodeproj`, select the `NotesEnglishShadow` scheme, set your signing team and bundle identifier, then build. From Terminal on a Mac:

```sh
xcodebuild -project NotesEnglishShadow.xcodeproj -scheme NotesEnglishShadow -destination 'platform=macOS' test
```

The app requests Accessibility permission only. After granting it in System Settings → Privacy & Security → Accessibility, restart the app. It needs no Input Monitoring, Screen Recording, Automation, or network permission.

## Privacy

The app runs only while Notes is frontmost. It reads at most 48 UTF-16 units immediately before the caret, keeps that bounded context in memory only, and persists only settings plus lexicon IDs and timestamps. It does not record keystrokes, modify Notes, log note text, or connect to the internet.

Apple may change Notes accessibility behavior in a future macOS release; compatibility cannot be guaranteed.

## Distribution

For release, use a real reverse-DNS bundle identifier, enable your Developer ID signing identity, archive with Hardened Runtime, and notarize the result. Do not distribute an ad-hoc signed build as a finished product.
