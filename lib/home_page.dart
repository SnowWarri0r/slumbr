import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'sleep_detector.dart';
import 'i18n.dart';

class SoundItem {
  final String Function(S) nameOf;
  final String asset;
  final IconData icon;
  SoundItem(this.nameOf, this.asset, this.icon);
}

class SoundCategory {
  final String Function(S) nameOf;
  final IconData icon;
  final List<SoundItem> sounds;
  SoundCategory(this.nameOf, this.icon, this.sounds);
}

final _categories = [
  SoundCategory((s) => s.rain, Icons.water_drop_outlined, [
    SoundItem((s) => s.heavyRain, 'assets/audio/rain/heavy-rain.mp3', Icons.thunderstorm_outlined),
    SoundItem((s) => s.lightRain, 'assets/audio/rain/light-rain.mp3', Icons.water_drop_outlined),
    SoundItem((s) => s.rainOnWindow, 'assets/audio/rain/rain-on-window.mp3', Icons.window_outlined),
    SoundItem((s) => s.rainOnTent, 'assets/audio/rain/rain-on-tent.mp3', Icons.night_shelter_outlined),
    SoundItem((s) => s.thunder, 'assets/audio/rain/thunder.mp3', Icons.bolt_outlined),
  ]),
  SoundCategory((s) => s.nature, Icons.eco_outlined, [
    SoundItem((s) => s.campfire, 'assets/audio/nature/campfire.mp3', Icons.whatshot_outlined),
    SoundItem((s) => s.river, 'assets/audio/nature/river.mp3', Icons.water_outlined),
    SoundItem((s) => s.waterfall, 'assets/audio/nature/waterfall.mp3', Icons.landscape_outlined),
    SoundItem((s) => s.waves, 'assets/audio/nature/waves.mp3', Icons.waves_outlined),
    SoundItem((s) => s.windInTrees, 'assets/audio/nature/wind-in-trees.mp3', Icons.park_outlined),
    SoundItem((s) => s.jungle, 'assets/audio/nature/jungle.mp3', Icons.forest_outlined),
    SoundItem((s) => s.crickets, 'assets/audio/nature/crickets.mp3', Icons.grass_outlined),
  ]),
  SoundCategory((s) => s.noise, Icons.equalizer_outlined, [
    SoundItem((s) => s.brownNoise, 'assets/audio/noise/brown-noise.wav', Icons.looks_one_outlined),
    SoundItem((s) => s.pinkNoise, 'assets/audio/noise/pink-noise.wav', Icons.looks_two_outlined),
    SoundItem((s) => s.whiteNoise, 'assets/audio/noise/white-noise.wav', Icons.looks_3_outlined),
  ]),
  SoundCategory((s) => s.other, Icons.auto_awesome_outlined, [
    SoundItem((s) => s.catPurring, 'assets/audio/other/cat-purring.mp3', Icons.pets_outlined),
    SoundItem((s) => s.singingBowl, 'assets/audio/other/singing-bowl.mp3', Icons.self_improvement_outlined),
    SoundItem((s) => s.insideATrain, 'assets/audio/other/inside-a-train.mp3', Icons.train_outlined),
    SoundItem((s) => s.underwater, 'assets/audio/other/underwater.mp3', Icons.scuba_diving_outlined),
  ]),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _player = AudioPlayer();
  SleepDetector? _detector;
  Timer? _fadeTimer;

  bool _isPlaying = false;
  double _baseVolume = 0.7;
  int _selectedCategory = 0;
  int _selectedSound = 0;
  SleepStage _stage = SleepStage.awake;
  double _volumeFactor = 1.0;
  double _currentVolume = 0.7;
  bool _calibrating = false;

  SoundItem get _currentSound => _categories[_selectedCategory].sounds[_selectedSound];

  static const _stageIcons = {
    SleepStage.awake: Icons.visibility,
    SleepStage.fallingAsleep: Icons.bedtime,
    SleepStage.lightSleep: Icons.nights_stay,
    SleepStage.deepSleep: Icons.dark_mode,
  };

  Map<SleepStage, String> _stageNames(S s) => {
    SleepStage.awake: s.awake,
    SleepStage.fallingAsleep: s.fallingAsleep,
    SleepStage.lightSleep: s.lightSleep,
    SleepStage.deepSleep: s.deepSleep,
  };

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _detector?.dispose();
    _player.dispose();
    super.dispose();
  }

  void _updateVolume() {
    final target = _baseVolume * _volumeFactor;
    _fadeTimer?.cancel();
    final start = _currentVolume;
    final delta = target - start;
    final steps = delta > 0 ? 50 : 20; // 升5秒，降2秒
    var step = 0;
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      step++;
      _currentVolume = start + delta * (step / steps);
      _player.setVolume(_currentVolume.clamp(0.0, 1.0));
      if (step >= steps) {
        t.cancel();
        if (_stage == SleepStage.deepSleep && _isPlaying) _stopAndShowSummary();
      }
    });
  }

  Future<void> _switchSound(int catIdx, int soundIdx) async {
    setState(() { _selectedCategory = catIdx; _selectedSound = soundIdx; });
    if (_isPlaying) {
      await _player.setAsset(_categories[catIdx].sounds[soundIdx].asset);
      await _player.setLoopMode(LoopMode.one);
      _player.play();
    }
  }

  void _stopAndShowSummary() async {
    final summary = _detector?.getSummary();
    await _player.stop();
    _detector?.stop();
    setState(() { _isPlaying = false; _stage = SleepStage.awake; _volumeFactor = 1.0; });
    if (summary != null && mounted) _showSummaryDialog(summary);
  }

  void _showSummaryDialog(SleepSummary summary) {
    final s = S.of(context);
    final names = _stageNames(s);
    final stageY = {
      SleepStage.awake: 3.0,
      SleepStage.fallingAsleep: 2.0,
      SleepStage.lightSleep: 1.0,
      SleepStage.deepSleep: 0.0,
    };
    final startTime = summary.records.first.timestamp;
    final spots = <FlSpot>[];
    for (var i = 0; i < summary.records.length; i++) {
      final x = summary.records[i].timestamp.difference(startTime).inSeconds / 60.0;
      final y = stageY[summary.records[i].stage]!;
      spots.add(FlSpot(x, y));
      // Add horizontal segment to next record
      if (i + 1 < summary.records.length) {
        final nextX = summary.records[i + 1].timestamp.difference(startTime).inSeconds / 60.0;
        spots.add(FlSpot(nextX, y));
      } else {
        final endX = summary.totalDuration.inSeconds / 60.0;
        spots.add(FlSpot(endX, y));
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.sleepSummary),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.totalDuration}: ${s.fmtDuration(summary.totalDuration)}'),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                width: 280,
                child: LineChart(LineChartData(
                  minY: -0.2,
                  maxY: 3.5,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}m', style: const TextStyle(fontSize: 10)),
                    )),
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final label = {3.0: names[SleepStage.awake], 2.0: names[SleepStage.fallingAsleep], 1.0: names[SleepStage.lightSleep], 0.0: names[SleepStage.deepSleep]};
                        return Text(label[v] ?? '', style: const TextStyle(fontSize: 9));
                      },
                    )),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, horizontalInterval: 1),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: Colors.teal.shade300,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.teal.withValues(alpha: 0.15)),
                    ),
                  ],
                )),
              ),
              const SizedBox(height: 16),
              Text(s.stageDurations, style: const TextStyle(fontWeight: FontWeight.bold)),
              ...summary.stageDurations.entries.map((e) {
                final pct = summary.totalDuration.inSeconds > 0
                    ? (e.value.inSeconds / summary.totalDuration.inSeconds * 100).toInt()
                    : 0;
                return Text('  ${names[e.key]}: ${s.fmtDuration(e.value)} ($pct%)');
              }),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(s.ok))],
      ),
    );
  }

  void _togglePlay() async {
    if (_isPlaying) {
      _stopAndShowSummary();
      return;
    }

    // Start playback immediately
    await _player.setAsset(_currentSound.asset);
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(_baseVolume);
    _currentVolume = _baseVolume;
    _player.play();
    setState(() { _isPlaying = true; _calibrating = true; });

    // Load VAD asynchronously
    _detector = SleepDetector(onStageChanged: (stage, factor) {
      setState(() { _stage = stage; _volumeFactor = factor; _calibrating = false; });
      _updateVolume();
    });

    final granted = await _detector!.start();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).micPermission)),
        );
      }
      await _player.stop();
      setState(() { _isPlaying = false; });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Slumbr')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: Icon(_currentSound.icon, size: 80, color: Colors.teal.shade300)),
          const SizedBox(height: 16),
          if (_isPlaying) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_stageIcons[_stage], size: 28),
                const SizedBox(width: 8),
                Text(
                  _calibrating ? s.calibrating : '${_stageNames(s)[_stage]} - ${s.volume} ${(_volumeFactor * 100).toInt()}%',
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Center(child: Text('${s.volume}: ${(_baseVolume * 100).toInt()}%')),
          Slider(value: _baseVolume, onChanged: (v) {
            setState(() => _baseVolume = v);
            _currentVolume = v * _volumeFactor;
            _player.setVolume(_currentVolume);
          }),
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton.icon(
              onPressed: _togglePlay,
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              label: Text(_isPlaying ? s.stop : s.start),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
            ),
          ),
          const SizedBox(height: 24),
          ..._buildSoundPicker(),
        ],
      ),
    );
  }

  List<Widget> _buildSoundPicker() {
    final s = S.of(context);
    return List.generate(_categories.length, (catIdx) {
      final cat = _categories[catIdx];
      return ExpansionTile(
        leading: Icon(cat.icon),
        title: Text(cat.nameOf(s)),
        initiallyExpanded: catIdx == _selectedCategory,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: List.generate(cat.sounds.length, (sIdx) {
              final sound = cat.sounds[sIdx];
              final selected = catIdx == _selectedCategory && sIdx == _selectedSound;
              return ChoiceChip(
                avatar: Icon(sound.icon, size: 18),
                label: Text(sound.nameOf(s)),
                selected: selected,
                onSelected: (_) => _switchSound(catIdx, sIdx),
              );
            }),
          ),
        ],
      );
    });
  }
}