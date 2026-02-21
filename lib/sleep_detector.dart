import 'dart:async';
import 'dart:typed_data';
import 'package:audio_streamer/audio_streamer.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vad/vad.dart';

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

  final _streamer = AudioStreamer();
  final _audioController = StreamController<Uint8List>.broadcast();
  StreamSubscription? _audioSub;
  VadHandler? _vadHandler;
  Timer? _checkTimer;

  DateTime _lastVoiceTime = DateTime.now();
  DateTime? _startTime;
  SleepStage _currentStage = SleepStage.awake;
  final List<SleepRecord> _records = [];

  SleepDetector({required this.onStageChanged});

  Future<bool> start() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;

    await _startForegroundService();

    _startTime = DateTime.now();
    _lastVoiceTime = DateTime.now();
    _records.add(SleepRecord(SleepStage.awake, DateTime.now()));

    // Start audio_streamer and convert float samples to PCM16 Uint8List
    _streamer.sampleRate = 16000;
    _audioSub = _streamer.audioStream.listen((samples) {
      final pcm = Int16List(samples.length);
      for (var i = 0; i < samples.length; i++) {
        pcm[i] = (samples[i].clamp(-1.0, 1.0) * 32767).toInt();
      }
      _audioController.add(pcm.buffer.asUint8List());
    });

    _vadHandler = VadHandler.create();
    _vadHandler!.onSpeechStart.listen((_) {
      _lastVoiceTime = DateTime.now();
      _emitCurrentState();
    });

    await _vadHandler!.startListening(
      positiveSpeechThreshold: 0.5,
      negativeSpeechThreshold: 0.35,
      audioStream: _audioController.stream,
    );

    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _emitCurrentState();
    });

    return true;
  }

  void _emitCurrentState() {
    final silence = DateTime.now().difference(_lastVoiceTime);
    final secs = silence.inSeconds.toDouble();
    SleepStage stage;
    double factor;

    // Awake: hold 1.0; then linear 1.0→0.1 over 10m~60m
    if (secs < 600) {
      stage = SleepStage.awake;
      factor = 1.0;
    } else if (secs < 1800) {
      stage = SleepStage.fallingAsleep;
      factor = 1.0 - ((secs - 600) / 3000) * 0.9;
    } else if (secs < 3600) {
      stage = SleepStage.lightSleep;
      factor = 1.0 - ((secs - 600) / 3000) * 0.9;
    } else {
      stage = SleepStage.deepSleep;
      factor = 0.1;
    }

    if (stage != _currentStage) {
      _currentStage = stage;
      _records.add(SleepRecord(stage, DateTime.now()));
    }
    onStageChanged(stage, factor);
  }

  SleepSummary? getSummary() {
    if (_startTime == null) return null;
    final total = DateTime.now().difference(_startTime!);
    final durations = <SleepStage, Duration>{};
    for (var i = 0; i < _records.length; i++) {
      final end = i + 1 < _records.length ? _records[i + 1].timestamp : DateTime.now();
      final d = end.difference(_records[i].timestamp);
      durations[_records[i].stage] = (durations[_records[i].stage] ?? Duration.zero) + d;
    }
    return SleepSummary(total, durations, List.of(_records));
  }

  void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _audioSub?.cancel();
    _audioSub = null;
    _vadHandler?.stopListening();
    FlutterForegroundTask.stopService();
  }

  void dispose() {
    stop();
    _audioController.close();
    _vadHandler?.dispose();
    _vadHandler = null;
  }

  Future<void> _startForegroundService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'slumbr_sleep',
        channelName: 'Sleep Monitoring',
        channelImportance: NotificationChannelImportance.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
      ),
    );
    await FlutterForegroundTask.startService(
      notificationTitle: 'Slumbr',
      notificationText: 'Monitoring sleep...',
      serviceTypes: [ForegroundServiceTypes.microphone],
    );
  }
}
