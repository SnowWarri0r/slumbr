import 'dart:async';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

enum SleepStage { awake, fallingAsleep, lightSleep, deepSleep }

class SleepRecord {
  final SleepStage stage;
  final DateTime timestamp;
  SleepRecord(this.stage, this.timestamp);
}

class SleepSummary {
  final Duration totalDuration;
  final Map<SleepStage, Duration> stageDurations;
  final List<SleepRecord> records;
  SleepSummary(this.totalDuration, this.stageDurations, this.records);
}

class SleepDetector {
  final void Function(SleepStage stage, double volumeFactor) onStageChanged;

  final _recorder = AudioRecorder();
  Timer? _pollTimer;
  Timer? _checkTimer;

  double _baselineDb = 0;
  final List<double> _calibrationReadings = [];
  bool _calibrating = true;
  DateTime _lastNoiseTime = DateTime.now();
  DateTime? _startTime;
  SleepStage _currentStage = SleepStage.awake;
  final List<SleepRecord> _records = [];

  static const _noiseThreshold = 5.0;

  SleepDetector({required this.onStageChanged});

  Future<bool> start() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    _calibrating = true;
    _calibrationReadings.clear();
    _lastNoiseTime = DateTime.now();
    _startTime = DateTime.now();
    _records.clear();
    _currentStage = SleepStage.awake;
    _records.add(SleepRecord(SleepStage.awake, _startTime!));

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/slumbr_monitor.wav';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);

    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      final amp = await _recorder.getAmplitude();
      final db = amp.current;
      if (db <= -160) return;

      if (_calibrating) {
        _calibrationReadings.add(db);
        return;
      }
      if (db > _baselineDb + _noiseThreshold) {
        _lastNoiseTime = DateTime.now();
      }
    });

    Timer(const Duration(seconds: 10), () {
      if (_calibrationReadings.isNotEmpty) {
        _baselineDb = _calibrationReadings.reduce((a, b) => a + b) /
            _calibrationReadings.length;
      }
      _calibrating = false;
      _startChecking();
    });

    return true;
  }

  void _startChecking() {
    onStageChanged(SleepStage.awake, 1.0);
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final quietSec =
          DateTime.now().difference(_lastNoiseTime).inSeconds;
      final quietMin = quietSec / 60.0;

      // Stage thresholds (minutes)
      final stage = switch (quietMin) {
        >= 15 => SleepStage.deepSleep,
        >= 8 => SleepStage.lightSleep,
        >= 3 => SleepStage.fallingAsleep,
        _ => SleepStage.awake,
      };

      // Smooth factor: linearly interpolate within each stage range
      // 0-3min → 1.0, 3-8min → 1.0→0.6, 8-15min → 0.6→0.3, 15+min → 0.3→0.0
      final factor = switch (quietMin) {
        >= 15 => (0.3 * (1.0 - ((quietMin - 15) / 5).clamp(0.0, 1.0))),
        >= 8 => 0.3 + 0.3 * (1.0 - (quietMin - 8) / 7),
        >= 3 => 0.6 + 0.4 * (1.0 - (quietMin - 3) / 5),
        _ => 1.0,
      };

      if (stage != _currentStage) {
        _currentStage = stage;
        _records.add(SleepRecord(stage, DateTime.now()));
      }
      onStageChanged(stage, factor.clamp(0.0, 1.0));
    });
  }

  SleepSummary getSummary() {
    final now = DateTime.now();
    final total = now.difference(_startTime ?? now);
    final durations = <SleepStage, Duration>{};
    for (var i = 0; i < _records.length; i++) {
      final end = i + 1 < _records.length ? _records[i + 1].timestamp : now;
      final d = end.difference(_records[i].timestamp);
      durations[_records[i].stage] = (durations[_records[i].stage] ?? Duration.zero) + d;
    }
    return SleepSummary(total, durations, List.unmodifiable(_records));
  }

  void stop() {
    _pollTimer?.cancel();
    _checkTimer?.cancel();
    _recorder.stop();
  }

  void dispose() {
    stop();
    _recorder.dispose();
  }
}
