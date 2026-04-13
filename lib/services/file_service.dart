import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/media_file.dart';

class FileService {
  static const _uuid = Uuid();

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final photos  = await Permission.photos.request();
      final videos  = await Permission.videos.request();
      final audio   = await Permission.audio.request();
      final storage = await Permission.storage.request();
      return photos.isGranted || videos.isGranted ||
             audio.isGranted  || storage.isGranted;
    }
    return true;
  }

  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      return await Permission.storage.isGranted  ||
             await Permission.photos.isGranted   ||
             await Permission.videos.isGranted;
    }
    return true;
  }

  Future<String?> pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'mov', 'avi', 'webm', 'flv', 'm4v', '3gp'],
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  Future<String?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'aac', 'm4a', 'wav', 'ogg', 'flac', 'opus'],
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  Future<String?> pickMediaFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: false,
    );
    return result?.files.single.path;
  }

  Future<String> getOutputDir() async {
    Directory dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/MediaTools');
    } else {
      final docs = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(docs.path, 'MediaTools'));
    }
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> buildOutputPath({
    required String inputPath,
    required String suffix,
    required String extension,
    String? customDir,
  }) async {
    final dir = customDir ?? await getOutputDir();
    final base = p.basenameWithoutExtension(inputPath);
    final name = '${base}_$suffix.$extension';
    return p.join(dir, name);
  }

  String resolveConflict(String path) {
    if (!File(path).existsSync()) return path;
    final dir  = p.dirname(path);
    final base = p.basenameWithoutExtension(path);
    final ext  = p.extension(path);
    final id   = _uuid.v4().substring(0, 6);
    return p.join(dir, '${base}_$id$ext');
  }

  Future<int> getFileSize(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return 0;
    }
  }

  bool fileExists(String path) => File(path).existsSync();

  Future<void> deleteFile(String path) async {
    try { await File(path).delete(); } catch (_) {}
  }

  Future<String> getHistoryDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'history'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<bool> hasSufficientSpace(int requiredBytes) async {
    return true;
  }

  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  MediaType detectType(String path) {
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    const videoExts = ['mp4', 'mkv', 'mov', 'avi', 'webm', 'flv', 'm4v', '3gp', 'wmv'];
    const audioExts = ['mp3', 'aac', 'm4a', 'wav', 'ogg', 'flac', 'opus', 'wma'];
    if (videoExts.contains(ext)) return MediaType.video;
    if (audioExts.contains(ext)) return MediaType.audio;
    return MediaType.unknown;
  }
}