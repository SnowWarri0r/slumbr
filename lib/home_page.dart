import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'sleep_detector.dart';

class SoundItem {
  final String name;
  final String asset;
  final IconData icon;
  const SoundItem(this.name, this.asset, this.icon);
}

class SoundCategory {
  final String name;
  final IconData icon;
  final List<SoundItem> sounds;
  const SoundCategory(this.name, this.icon, this.sounds);
}

const _categories = [
  SoundCategory('雨声', Icons.water_drop_outlined, [
    SoundItem('暴雨', 'assets/audio/rain/heavy-rain.mp3', Icons.thunderstorm_outlined),
    SoundItem('细雨', 'assets/audio/rain/light-rain.mp3', Icons.water_drop_outlined),
    SoundItem('窗边雨', 'assets/audio/rain/rain-on-window.mp3', Icons.window_outlined),
    SoundItem('帐篷雨', 'assets/audio/rain/rain-on-tent.mp3', Icons.night_shelter_outlined),
    SoundItem('雷声', 'assets/audio/rain/thunder.mp3', Icons.bolt_outlined),
  ]),
  SoundCategory('自然', Icons.eco_outlined, [
    SoundItem('篝火', 'assets/audio/nature/campfire.mp3', Icons.whatshot_outlined),
    SoundItem('溪流', 'assets/audio/nature/river.mp3', Icons.water_outlined),
    SoundItem('瀑布', 'assets/audio/nature/waterfall.mp3', Icons.landscape_outlined),
    SoundItem('海浪', 'assets/audio/nature/waves.mp3', Icons.waves_outlined),
    SoundItem('林风', 'assets/audio/nature/wind-in-trees.mp3', Icons.park_outlined),
    SoundItem('丛林', 'assets/audio/nature/jungle.mp3', Icons.forest_outlined),
    SoundItem('蟋蟀', 'assets/audio/nature/crickets.mp3', Icons.grass_outlined),
  ]),
  SoundCategory('噪音', Icons.equalizer_outlined, [
    SoundItem('棕噪音', 'assets/audio/noise/brown-noise.wav', Icons.looks_one_outlined),
    SoundItem('粉噪音', 'assets/audio/noise/pink-noise.wav', Icons.looks_two_outlined),
    SoundItem('白噪音', 'assets/audio/noise/white-noise.wav', Icons.looks_3_outlined),
  ]),
  SoundCategory('其他', Icons.auto_awesome_outlined, [
    SoundItem('猫咪', 'assets/audio/other/cat-purring.mp3', Icons.pets_outlined),
    SoundItem('颂钵', 'assets/audio/other/singing-bowl.mp3', Icons.self_improvement_outlined),
    SoundItem('火车', 'assets/audio/other/inside-a-train.mp3', Icons.train_outlined),
    SoundItem('水下', 'assets/audio/other/underwater.mp3', Icons.scuba_diving_outlined),
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

  bool _isPlaying = false;
  double _baseVolume = 0.7;
  int _selectedCategory = 0;
  int _selectedSound = 0;
  SleepStage _stage = SleepStage.awake;
  double _volumeFactor = 1.0;
  bool _calibrating = false;

  SoundItem get _currentSound => _categories[_selectedCategory].sounds[_selectedSound];

  static const _stageInfo = {
    SleepStage.awake: ('监测中...', Icons.visibility, 1.0),
    SleepStage.fallingAsleep: ('入睡中 - 音量 60%', Icons.bedtime, 0.6),
    SleepStage.lightSleep: ('浅睡眠 - 音量 30%', Icons.nights_stay, 0.3),
    SleepStage.deepSleep: ('深睡眠 - 即将停止', Icons.dark_mode, 0.0),
  };

  @override
  void dispose() {
    _detector?.dispose();
    _player.dispose();
    super.dispose();
  }

  void _updateVolume() {
    _player.setVolume(_baseVolume * _volumeFactor);
    if (_stage == SleepStage.deepSleep) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_stage == SleepStage.deepSleep && _isPlaying) _stopAndShowSummary();
      });
    }
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
    String fmt(Duration d) => '${d.inMinutes}分${d.inSeconds % 60}秒';
    const stageNames = {
      SleepStage.awake: '清醒',
      SleepStage.fallingAsleep: '入睡中',
      SleepStage.lightSleep: '浅睡眠',
      SleepStage.deepSleep: '深睡眠',
    };
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('睡眠总结'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('总监测时长: ${fmt(summary.totalDuration)}'),
              const SizedBox(height: 12),
              const Text('各阶段时长:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...summary.stageDurations.entries.map((e) {
                final pct = summary.totalDuration.inSeconds > 0
                    ? (e.value.inSeconds / summary.totalDuration.inSeconds * 100).toInt()
                    : 0;
                return Text('  ${stageNames[e.key]}: ${fmt(e.value)} ($pct%)');
              }),
              const SizedBox(height: 12),
              const Text('阶段变化:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...summary.records.map((r) =>
                Text('  ${r.timestamp.hour}:${r.timestamp.minute.toString().padLeft(2, '0')} → ${stageNames[r.stage]}'),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定'))],
      ),
    );
  }

  void _togglePlay() async {
    if (_isPlaying) {
      _stopAndShowSummary();
      return;
    }

    _detector = SleepDetector(onStageChanged: (stage, factor) {
      setState(() { _stage = stage; _volumeFactor = factor; _calibrating = false; });
      _updateVolume();
    });

    final granted = await _detector!.start();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('需要麦克风权限来检测睡眠')),
        );
      }
      return;
    }

    await _player.setAsset(_currentSound.asset);
    await _player.setLoopMode(LoopMode.one);
    await _player.setVolume(_baseVolume);
    _player.play();
    setState(() { _isPlaying = true; _calibrating = true; });
  }

  @override
  Widget build(BuildContext context) {
    final stageEntry = _stageInfo[_stage]!;
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
                Icon(stageEntry.$2, size: 28),
                const SizedBox(width: 8),
                Text(
                  _calibrating ? '校准中...' : stageEntry.$1,
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Center(child: Text('音量: ${(_baseVolume * 100).toInt()}%')),
          Slider(value: _baseVolume, onChanged: (v) {
            setState(() => _baseVolume = v);
            _player.setVolume(v * _volumeFactor);
          }),
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton.icon(
              onPressed: _togglePlay,
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
              label: Text(_isPlaying ? '停止' : '开始'),
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
    return List.generate(_categories.length, (catIdx) {
      final cat = _categories[catIdx];
      return ExpansionTile(
        leading: Icon(cat.icon),
        title: Text(cat.name),
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
                label: Text(sound.name),
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