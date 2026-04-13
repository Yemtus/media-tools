import 'package:flutter/foundation.dart';
import '../models/media_file.dart';
import '../services/ffmpeg_service.dart';
import '../services/file_service.dart';

class AppProvider extends ChangeNotifier {
  final FFmpegService ffmpeg = FFmpegService();
  final FileService   files  = FileService();

  final List<ProcessingJob> _history = [];
  List<ProcessingJob> get history => List.unmodifiable(_history);

  void addJob(ProcessingJob job) {
    _history.insert(0, job);
    notifyListeners();
  }

  void updateJob(ProcessingJob job) {
    final idx = _history.indexWhere((j) => j.id == job.id);
    if (idx >= 0) {
      _history[idx] = job;
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  MediaFile? _selectedFile;
  MediaFile? get selectedFile => _selectedFile;

  void setSelectedFile(MediaFile? file) {
    _selectedFile = file;
    notifyListeners();
  }

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  double _progress = 0;
  double get progress => _progress;

  String _statusMessage = '';
  String get statusMessage => _statusMessage;

  void setProcessing(bool v, {String message = ''}) {
    _isProcessing = v;
    _statusMessage = message;
    if (!v) _progress = 0;
    notifyListeners();
  }

  void setProgress(double v, {String? message}) {
    _progress = v;
    if (message != null) _statusMessage = message;
    notifyListeners();
  }
}