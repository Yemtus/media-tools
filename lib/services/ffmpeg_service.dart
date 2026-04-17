import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import '../models/media_file.dart';

class FFmpegService {
  int? _activeSessionId;

  Future<MediaFile?> probeFile(String filePath) async {
    try {
      final file = File(filePath);
      final size = await file.length();
      final name = p.basename(filePath);
      final ext  = p.extension(filePath).toLowerCase();

      final videoExts = ['.mp4', '.mkv', '.mov', '.avi', '.webm', '.flv'];
      final audioExts = ['.mp3', '.aac', '.m4a', '.wav', '.ogg', '.flac'];

      MediaType type = MediaType.unknown;
      if (videoExts.contains(ext)) type = MediaType.video;
      if (audioExts.contains(ext)) type = MediaType.audio;

      String? duration;
      String? resolution;
      String? codec;
      String? bitrate;

      final session = await FFprobeKit.getMediaInformation(filePath);
      final info = session.getMediaInformation();

      if (info != null) {
        final rawDuration = info.getDuration();
        if (rawDuration != null) {
          final secs = double.tryParse(rawDuration) ?? 0;
          final d = Duration(seconds: secs.toInt());
          final h = d.inHours.toString().padLeft(2, '0');
          final m = (d.inMinutes % 60).toString().padLeft(2, '0');
          final s = (d.inSeconds % 60).toString().padLeft(2, '0');
          duration = '$h:$m:$s';
        }
        final rawBitrate = info.getBitrate();
        if (rawBitrate != null) {
          final kbps = (int.tryParse(rawBitrate) ?? 0) ~/ 1000;
          bitrate = '${kbps}kbps';
        }
        final streams = info.getStreams();
        if (streams != null) {
          for (final stream in streams) {
            final codecType = stream.getType();
            if (codecType == 'video') {
              codec = stream.getCodec();
              final w = stream.getWidth();
              final h = stream.getHeight();
              if (w != null && h != null) resolution = '${w}x$h';
            } else if (codecType == 'audio' && codec == null) {
              codec = stream.getCodec();
            }
          }
        }
      }

      return MediaFile(
        path: filePath,
        name: name,
        sizeBytes: size,
        duration: duration ?? 'Unknown',
        resolution: resolution,
        codec: codec,
        bitrate: bitrate,
        type: type,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> compressVideo({
    required String inputPath,
    required String outputPath,
    required CompressionSettings settings,
    void Function(double progress)? onProgress,
  }) async {
    final duration = await _getFileDurationMs(inputPath);
    final bitrate   = settings.customBitrate   ?? '1500k';
    final resolution = settings.customResolution ?? '1280x720';

    final cmd = '-i "$inputPath" '
        '-vcodec libx264 -b:v $bitrate -vf scale=$resolution '
        '-acodec aac -b:a 128k -y "$outputPath"';

    return _execute(cmd, duration, onProgress);
  }

  Future<bool> compressAudio({
    required String inputPath,
    required String outputPath,
    required String bitrate,
    required AudioFormat format,
    void Function(double progress)? onProgress,
  }) async {
    final duration = await _getFileDurationMs(inputPath);
    final cmd = '-i "$inputPath" -codec:a ${format.codec} -b:a $bitrate -y "$outputPath"';
    return _execute(cmd, duration, onProgress);
  }

  Future<bool> trimVideo({
    required String inputPath,
    required String outputPath,
    required TrimSettings trim,
    void Function(double progress)? onProgress,
  }) async {
    final duration = trim.duration.inMilliseconds.toDouble();
    final cmd = '-i "$inputPath" -ss ${trim.toFFmpegStart()} '
        '-t ${trim.toFFmpegDuration()} -c copy -y "$outputPath"';
    return _execute(cmd, duration, onProgress);
  }

  Future<bool> trimAudio({
    required String inputPath,
    required String outputPath,
    required TrimSettings trim,
    void Function(double progress)? onProgress,
  }) async {
    final duration = trim.duration.inMilliseconds.toDouble();
    final cmd = '-i "$inputPath" -ss ${trim.toFFmpegStart()} '
        '-t ${trim.toFFmpegDuration()} -c copy -y "$outputPath"';
    return _execute(cmd, duration, onProgress);
  }

  Future<bool> convertVideoToAudio({
    required String inputPath,
    required String outputPath,
    required ConvertSettings settings,
    void Function(double progress)? onProgress,
  }) async {
    final duration = await _getFileDurationMs(inputPath);
    final bitrate  = settings.audioBitrate ?? '192k';
    final cmd = '-i "$inputPath" -vn -codec:a ${settings.outputFormat.codec} '
        '-b:a $bitrate -y "$outputPath"';
    return _execute(cmd, duration, onProgress);
  }

  Future<List<String>> splitVideoByTime({
    required String inputPath,
    required String outputDir,
    required int segmentSeconds,
    void Function(double progress)? onProgress,
  }) async {
    final duration = await _getFileDurationMs(inputPath);
    final ext = p.extension(inputPath);
    final outputPattern = p.join(outputDir, 'part_%03d$ext');
    final cmd = '-i "$inputPath" -f segment -segment_time $segmentSeconds '
        '-c copy -reset_timestamps 1 -y "$outputPattern"';
    final success = await _execute(cmd, duration, onProgress);
    if (!success) return [];
    return _listOutputFiles(outputDir, 'part_', ext);
  }

  Future<List<String>> splitVideoEqualParts({
    required String inputPath,
    required String outputDir,
    required int parts,
    void Function(double progress)? onProgress,
  }) async {
    final durationMs = await _getFileDurationMs(inputPath);
    final segmentSeconds = ((durationMs / 1000) / parts).ceil();
    return splitVideoByTime(
      inputPath: inputPath,
      outputDir: outputDir,
      segmentSeconds: segmentSeconds,
      onProgress: onProgress,
    );
  }

  Future<List<String>> splitAudioByTime({
    required String inputPath,
    required String outputDir,
    required int segmentSeconds,
    void Function(double progress)? onProgress,
  }) async {
    final duration = await _getFileDurationMs(inputPath);
    final ext = p.extension(inputPath);
    final outputPattern = p.join(outputDir, 'part_%03d$ext');
    final cmd = '-i "$inputPath" -f segment -segment_time $segmentSeconds '
        '-c copy -reset_timestamps 1 -y "$outputPattern"';
    final success = await _execute(cmd, duration, onProgress);
    if (!success) return [];
    return _listOutputFiles(outputDir, 'part_', ext);
  }

  Future<void> cancel() async {
    if (_activeSessionId != null) {
      await FFmpegKit.cancel(_activeSessionId!);
      _activeSessionId = null;
    } else {
      await FFmpegKit.cancel();
    }
  }

  Future<bool> _execute(
    String command,
    double totalDurationMs,
    void Function(double)? onProgress,
  ) async {
    final completer = Completer<bool>();

    final session = await FFmpegKit.executeAsync(
      command,
      (session) async {
        final code = await session.getReturnCode();
        _activeSessionId = null;
        completer.complete(ReturnCode.isSuccess(code));
      },
      null,
      (stats) {
        if (onProgress != null && totalDurationMs > 0) {
          final currentMs = stats.getTime().toDouble();
          final progress  = (currentMs / totalDurationMs).clamp(0.0, 1.0);
          onProgress(progress);
        }
      },
    );

    _activeSessionId = session.getSessionId();
    return completer.future;
  }

  Future<double> _getFileDurationMs(String filePath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final info = session.getMediaInformation();
      if (info != null) {
        final raw = info.getDuration();
        if (raw != null) {
          final secs = double.tryParse(raw) ?? 0;
          return secs * 1000;
        }
      }
    } catch (_) {}
    return 0;
  }

  List<String> _listOutputFiles(String dir, String prefix, String ext) {
    try {
      return Directory(dir)
          .listSync()
          .whereType<File>()
          .map((f) => f.path)
          .where((path) =>
              p.basename(path).startsWith(prefix) && path.endsWith(ext))
          .toList()
        ..sort();
    } catch (_) {
      return [];
    }
  }
}