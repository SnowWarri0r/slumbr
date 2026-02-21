import 'dart:async';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

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

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: '');

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
      final quietMinutes =
          DateTime.now().difference(_lastNoiseTime).inMinutes;
      final (stage, factor) = switch (quietMinutes) {
        >= 15 => (SleepStage.deepSleep, 0.0),
        >= 8 => (SleepStage.lightSleep, 0.3),
        >= 3 => (SleepStage.fallingAsleep, 0.6),
        _ => (SleepStage.awake, 1.0),
      };
      if (stage != _currentStage) {
        _currentStage = stage;
        _records.add(SleepRecord(stage, DateTime.now()));
      }
      onStageChanged(stage, factor);
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
