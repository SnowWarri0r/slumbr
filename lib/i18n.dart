import 'package:flutter/widgets.dart';

class S {
  static S of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'zh' ? S._zh() : S._en();
  }

  // Categories
  final String rain, nature, noise, other;
  // Rain sounds
  final String heavyRain, lightRain, rainOnWindow, rainOnTent, thunder;
  // Nature sounds
  final String campfire, river, waterfall, waves, windInTrees, jungle, crickets;
  // Noise sounds
  final String brownNoise, pinkNoise, whiteNoise;
  // Other sounds
  final String catPurring, singingBowl, insideATrain, underwater;
  // Stages
  final String awake, fallingAsleep, lightSleep, deepSleep;
  // UI
  final String calibrating, volume, start, stop, sleepSummary, totalDuration;
  final String stageDurations, stageChanges, ok, micPermission;

  S._en()
      : rain = 'Rain', nature = 'Nature', noise = 'Noise', other = 'Other',
        heavyRain = 'Heavy Rain', lightRain = 'Light Rain',
        rainOnWindow = 'Rain on Window', rainOnTent = 'Rain on Tent',
        thunder = 'Thunder', campfire = 'Campfire', river = 'River',
        waterfall = 'Waterfall', waves = 'Waves',
        windInTrees = 'Wind in Trees', jungle = 'Jungle',
        crickets = 'Crickets', brownNoise = 'Brown', pinkNoise = 'Pink',
        whiteNoise = 'White', catPurring = 'Cat Purring',
        singingBowl = 'Singing Bowl', insideATrain = 'Train',
        underwater = 'Underwater', awake = 'Monitoring',
        fallingAsleep = 'Falling Asleep', lightSleep = 'Light Sleep',
        deepSleep = 'Deep Sleep', calibrating = 'Calibrating...',
        volume = 'Volume', start = 'Start', stop = 'Stop',
        sleepSummary = 'Sleep Summary', totalDuration = 'Total Duration',
        stageDurations = 'Stage Durations:', stageChanges = 'Stage Changes:',
        ok = 'OK', micPermission = 'Microphone permission required';

  S._zh()
      : rain = '雨声', nature = '自然', noise = '噪音', other = '其他',
        heavyRain = '暴雨', lightRain = '细雨', rainOnWindow = '窗边雨',
        rainOnTent = '帐篷雨', thunder = '雷声', campfire = '篝火',
        river = '溪流', waterfall = '瀑布', waves = '海浪',
        windInTrees = '林风', jungle = '丛林', crickets = '蟋蟀',
        brownNoise = '棕噪音', pinkNoise = '粉噪音', whiteNoise = '白噪音',
        catPurring = '猫咪', singingBowl = '颂钵', insideATrain = '火车',
        underwater = '水下', awake = '监测中', fallingAsleep = '入睡中',
        lightSleep = '浅睡眠', deepSleep = '深睡眠',
        calibrating = '校准中...', volume = '音量', start = '开始',
        stop = '停止', sleepSummary = '睡眠总结', totalDuration = '总监测时长',
        stageDurations = '各阶段时长:', stageChanges = '阶段变化:',
        ok = '确定', micPermission = '需要麦克风权限来检测睡眠';

  String fmtDuration(Duration d) => '${d.inMinutes}m${d.inSeconds % 60}s';
}
