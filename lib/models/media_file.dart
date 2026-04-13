class MediaFile {
  final String path;
  final String name;
  final int sizeBytes;
  final String? duration;
  final String? resolution;
  final String? codec;
  final String? bitrate;
  final MediaType type;

  MediaFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    this.duration,
    this.resolution,
    this.codec,
    this.bitrate,
    required this.type,
  });

  String get readableSize {
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get extension => name.split('.').last.toUpperCase();
}

enum MediaType { video, audio, unknown }

class ProcessingJob {
  final String id;
  final String inputPath;
  final String outputPath;
  final JobType jobType;
  JobStatus status;
  double progress;
  String? errorMessage;
  DateTime createdAt;
  int? inputSizeBytes;
  int? outputSizeBytes;
  Duration? processingTime;

  ProcessingJob({
    required this.id,
    required this.inputPath,
    required this.outputPath,
    required this.jobType,
    this.status = JobStatus.pending,
    this.progress = 0,
    this.errorMessage,
    this.inputSizeBytes,
    this.outputSizeBytes,
    this.processingTime,
  }) : createdAt = DateTime.now();

  double get compressionRatio {
    if (inputSizeBytes == null || outputSizeBytes == null || inputSizeBytes == 0) return 0;
    return 1 - (outputSizeBytes! / inputSizeBytes!);
  }

  String get savedSizeReadable {
    final saved = (inputSizeBytes ?? 0) - (outputSizeBytes ?? 0);
    if (saved < 0) return '0 KB';
    if (saved < 1024 * 1024) return '${(saved / 1024).toStringAsFixed(0)} KB';
    return '${(saved / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum JobType { compressVideo, compressAudio, trimVideo, trimAudio, convertToAudio, splitVideo, splitAudio }
enum JobStatus { pending, running, completed, failed, cancelled }

extension JobTypeX on JobType {
  String get label {
    switch (this) {
      case JobType.compressVideo:   return 'Compress Video';
      case JobType.compressAudio:   return 'Compress Audio';
      case JobType.trimVideo:       return 'Trim Video';
      case JobType.trimAudio:       return 'Trim Audio';
      case JobType.convertToAudio:  return 'Convert to Audio';
      case JobType.splitVideo:      return 'Split Video';
      case JobType.splitAudio:      return 'Split Audio';
    }
  }
}

class CompressionSettings {
  final CompressionQuality quality;
  final String? customBitrate;
  final String? customResolution;

  const CompressionSettings({
    required this.quality,
    this.customBitrate,
    this.customResolution,
  });

  static const CompressionSettings lowSize = CompressionSettings(
    quality: CompressionQuality.low,
    customBitrate: '500k',
    customResolution: '854x480',
  );

  static const CompressionSettings balanced = CompressionSettings(
    quality: CompressionQuality.balanced,
    customBitrate: '1500k',
    customResolution: '1280x720',
  );

  static const CompressionSettings highQuality = CompressionSettings(
    quality: CompressionQuality.high,
    customBitrate: '3000k',
    customResolution: '1920x1080',
  );
}

enum CompressionQuality { low, balanced, high }

class TrimSettings {
  final Duration startTime;
  final Duration endTime;

  const TrimSettings({required this.startTime, required this.endTime});

  Duration get duration => endTime - startTime;

  String toFFmpegStart() => _durationToFFmpeg(startTime);
  String toFFmpegDuration() => _durationToFFmpeg(duration);

  static String _durationToFFmpeg(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class SplitSettings {
  final SplitMode mode;
  final int value;
  const SplitSettings({required this.mode, required this.value});
}

enum SplitMode { byTime, bySize, equalParts }

class ConvertSettings {
  final AudioFormat outputFormat;
  final String? audioBitrate;
  const ConvertSettings({required this.outputFormat, this.audioBitrate});
}

enum AudioFormat { mp3, aac, m4a, wav, ogg, flac }

extension AudioFormatX on AudioFormat {
  String get extension {
    switch (this) {
      case AudioFormat.mp3:  return 'mp3';
      case AudioFormat.aac:  return 'aac';
      case AudioFormat.m4a:  return 'm4a';
      case AudioFormat.wav:  return 'wav';
      case AudioFormat.ogg:  return 'ogg';
      case AudioFormat.flac: return 'flac';
    }
  }

  String get codec {
    switch (this) {
      case AudioFormat.mp3:  return 'libmp3lame';
      case AudioFormat.aac:  return 'aac';
      case AudioFormat.m4a:  return 'aac';
      case AudioFormat.wav:  return 'pcm_s16le';
      case AudioFormat.ogg:  return 'libvorbis';
      case AudioFormat.flac: return 'flac';
    }
  }
}