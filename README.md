# Verba

Native macOS voice-to-text and writing assistant.

## Project structure

```text
Sources/Verba/
├── App/
│   ├── VerbaApp.swift             # Application entry point
│   └── AppDelegate.swift          # Menu bar app lifecycle and composition root
├── Features/
│   ├── Activation/                # Shortcut and focused-field detection
│   ├── Capture/                   # Microphone access and recording state
│   ├── Transcription/             # Speech-to-text providers
│   ├── Writing/                   # Grammar, tone, and rewriting actions
│   ├── TextInsertion/             # Accessibility-based text replacement
│   └── Overlay/                   # Floating microphone/timer/result UI
├── Infrastructure/
│   ├── Accessibility/             # AXUIElement and permission handling
│   ├── Audio/                      # AVAudioEngine and audio session setup
│   ├── Intelligence/              # Apple Foundation Models integration
│   └── Persistence/               # Preferences and local history
└── Shared/
    ├── Models/                    # Shared domain types
    └── Support/                   # Small reusable utilities

Tests/VerbaTests/
└── ...                            # Unit and integration tests
```

## Architectural direction

Verba is intentionally macOS-only and Swift-only. SwiftUI will own the visual components, while AppKit will handle the menu bar app, floating panels, global events, accessibility, and text insertion.

The first implementation should use explicit protocols around transcription, writing intelligence, and text insertion. This lets us test the state machine without requiring a microphone, Accessibility permission, or an Apple Intelligence-capable Mac.
