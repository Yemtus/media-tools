import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/media_file.dart';

class FFmpegService {
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

      return MediaFile(
        path: filePath,
        name: name,
        sizeBytes: size,
        duration: 'Unknown',
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
    return _simulateProgress(onProgress);
  }

  Future<bool> compressAudio({
    required String inputPath,
    required String outputPath,
    required String bitrate,
    required AudioFormat format,
    void Function(double progress)? onProgress,
  }) async {
    return _simulateProgress(onProgress);
  }

  Future<bool> trimVideo({
    required String inputPath,
    required String outputPath,
    required TrimSettings trim,
    void Function(double progress)? onProgress,
  }) async {
    return _simulateProgress(onProgress);
  }

  Future<bool> trimAudio({
    required String inputPath,
    required String outputPath,
    required TrimSettings trim,
    void Function(double progress)? onProgress,
  }) async {
    return _simulateProgress(onProgress);
  }

  Future<bool> convertVideoToAudio({
    required String inputPath,
    required String outputPath,
    required ConvertSettings settings,
    void Function(double progress)? onProgress,
  }) async {
    return _simulateProgress(onProgress);
  }

  Future<List<String>> splitVideoByTime({
    required String inputPath,
    required String outputDir,
    required int segmentSeconds,
    void Function(double progress)? onProgress,
  }) async {
    await _simulateProgress(onProgress);
    return [];
  }

  Future<List<String>> splitVideoEqualParts({
    required String inputPath,
    required String outputDir,
    required int parts,
    void Function(double progress)? onProgress,
  }) async {
    await _simulateProgress(onProgress);
    return [];
  }

  Future<List<String>> splitAudioByTime({
    required String inputPath,
    required String outputDir,
    required int segmentSeconds,
    void Function(double progress)? onProgress,
  }) async {
    await _simulateProgress(onProgress);
    return [];
  }

  Future<void> cancel() async {}

  Future<bool> _simulateProgress(void Function(double)? onProgress) async {
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      onProgress?.call(i / 10.0);
    }
    return true;
  }
}