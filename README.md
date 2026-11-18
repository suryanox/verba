# Verba

Native macOS voice-to-text and writing assistant.

## Requirements

- A Mac with Apple silicon (M1 or later)
- macOS 15 or later to build and run
- Xcode 16 or later (Swift 6)
- macOS 26 with Apple Intelligence turned on, for the AI features: fix, polish, shorten, tone, Ask AI, and Research. Dictation and editing work without it.
- Microphone and Speech Recognition permission, which the app asks for on first launch
- An internet connection for Research, which downloads the page you give it. The AI itself runs on your Mac.
- Optional: [SwiftLint](https://github.com/realm/SwiftLint) (`brew install swiftlint`) for `make check`

## How to run

```bash
make app
open .build/Verba.app
```

Other commands:

```bash
make test    # run the tests
make check   # lint, test, and build
make icon    # regenerate the app icon
```

## Screenshots

<p align="center">
  <img src="screenshots/screenshot-1.png" alt="Verba screenshot 1" width="820">
</p>

<p align="center">
  <img src="screenshots/screenshot-2.png" alt="Verba screenshot 2" width="405">
  <img src="screenshots/screenshot-3.png" alt="Verba screenshot 3" width="405">
</p>

## Features

- **Speak or type:** dictate with the microphone button or `⌥Space`, or just start typing. Dictation is added to what you already wrote.
- **Writing tools:** fix grammar, polish, shorten, or change tone (`⌘1`, `⌘2`, `⌘3`) using on-device Apple Intelligence.
- **Undo, redo, and history:** `⌘Z` works across typing, dictation, and AI edits, and the History popover keeps restorable snapshots between launches.
- **Personal look:** four themes (Midnight, Graphite, Paper, Sepia), four typefaces, adjustable size, line spacing, and column width.
- **Focus mode:** the toolbar fades while you type and returns when you move the mouse.
- **Three modes:** a switcher at the bottom picks **Write**, **Ask AI**, or **Research**, and the controls below it change to match.
- **Ask AI:** dictate a prompt and the on-device AI's answer is added to your document.
- **Research:** paste an article link and get a plain-language lesson in a fixed shape (what it's about, how they did it, what they found), plus a simple diagram of the steps, like a patient teacher explaining it to a beginner.
- **Drafts autosave** and can be exported as plain text with `⌘S`.

## Architectural direction

Verba is intentionally macOS-only and Swift-only. SwiftUI will own the visual components, while AppKit will handle the menu bar app, floating panels, global events, accessibility, and text insertion.

The first implementation should use explicit protocols around transcription, writing intelligence, and text insertion. This lets us test the state machine without requiring a microphone, Accessibility permission, or an Apple Intelligence-capable Mac.

## Patterns in use

- **State machine:** `VerbaSession` owns the legal lifecycle transitions.
- **Ports and adapters:** `Transcriber`, `TextInserter`, `WritingAssistant`, and `ActivationController` isolate system services from feature logic.
- **Coordinator/composition root:** `AppCoordinator` constructs and connects application services; UI and delegates do not create infrastructure directly.
- **MVVM where needed:** overlay screens will keep presentation state in view models instead of embedding behavior in SwiftUI views.
