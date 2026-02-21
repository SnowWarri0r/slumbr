# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Slumbr - Smart sleep-aid app that plays ambient sounds and auto-fades volume using Silero VAD voice detection.

## Commands

```bash
flutter pub get       # Install dependencies
flutter run           # Run on connected device
flutter analyze       # Static analysis
flutter clean         # Clean build artifacts
flutter build apk     # Build Android APK
```

## Architecture

- `lib/main.dart` - App entry, MaterialApp with i18n (en/zh)
- `lib/home_page.dart` - Main UI: sound picker, playback, volume fade, sleep summary with fl_chart
- `lib/sleep_detector.dart` - audio_streamer + Silero VAD voice detection, sleep stage tracking, foreground service
- `lib/i18n.dart` - Lightweight i18n (Chinese/English) via locale detection
- `assets/audio/{rain,nature,noise,other}/` - 19 ambient sounds from Moodist

## Key Dependencies

- `just_audio` - Audio playback with looping and volume control
- `audio_streamer` - Raw PCM microphone capture (feeds into VAD)
- `vad` - Silero VAD model for voice activity detection
- `flutter_foreground_task` - Android foreground service for screen-off operation
- `fl_chart` - Sleep summary timeline chart
- `permission_handler` - Microphone permission

## Sleep Detection Pipeline

audio_streamer (PCM float) → convert to PCM16 Uint8List → Silero VAD → onSpeechStart → reset silence timer

Stages: awake (0-10min, 100%) → fallingAsleep (10-30min) → lightSleep (30-60min) → deepSleep (60min+, 10%, auto-stop)

## Android Configuration

- compileSdk: 36, targetSdk: 34, minSdk: 21
- NDK: 29.0.14206865
- Java 17, Gradle 8.9
- Foreground service permissions: FOREGROUND_SERVICE, FOREGROUND_SERVICE_MICROPHONE
