# Slumbr

A sleep-aid app that plays natural ambient sounds and automatically fades volume as you fall asleep.

## Features

- **19 curated sounds** across 4 categories: Rain, Nature, Noise, Other
- **Sleep detection** via microphone — monitors ambient noise to determine sleep stage
- **Auto volume fade** — gradually reduces volume as you drift off until playback stops
- **Switch sounds while playing** — no need to restart the session
- **Sleep summary** — shows total duration, stage breakdown, and timeline on stop

## How It Works

1. Pick a sound and tap Start
2. The app calibrates for ~10 seconds using your microphone
3. As your environment gets quieter, it detects sleep stages:
   - **Awake** — full volume
   - **Falling Asleep** (3+ min quiet) — 60% volume
   - **Light Sleep** (8+ min quiet) — 30% volume
   - **Deep Sleep** (15+ min quiet) — stops playback
4. A summary dialog shows your sleep stage history when stopped

## Getting Started

```bash
flutter pub get
flutter run
```

## Tech Stack

- **Flutter** with Material Design
- **just_audio** — audio playback with looping and volume control
- **record** — microphone amplitude monitoring for sleep detection
- **permission_handler** — runtime permission requests

## Sound Credits

Ambient sounds sourced from [Moodist](https://github.com/remvze/moodist) (MIT License).

## License

MIT
