# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ear Savior - 突发性耳聋辅助治疗 App，播放自然白噪音帮助用户入睡，定时渐弱音量。

## Commands

```bash
# 获取依赖
flutter pub get

# 运行应用
flutter run

# 代码分析
flutter analyze

# 清理构建
flutter clean
```

## Architecture

- `lib/main.dart` - 应用入口，MaterialApp 配置
- `lib/home_page.dart` - 主页面，包含音频播放和定时器逻辑
- `assets/audio/` - 白噪音音频资源 (rain.mp3, river.mp3, waves.mp3, forest.mp3)

## Key Dependencies

- `just_audio` - 音频播放，支持循环和音量控制
- `audio_session` - 音频会话管理
- `permission_handler` - 权限请求（麦克风等）

## Android Configuration

- compileSdk: 36, targetSdk: 34, minSdk: 21
- Java 17 required
- Gradle 8.9
