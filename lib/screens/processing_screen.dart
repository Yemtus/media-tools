import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/media_file.dart';
import '../providers/app_provider.dart';
import '../widgets/shared_widgets.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final ProcessingJob       job;
  final String              label;
  final Color               accentColor;
  final CompressionSettings? settings;
  final AudioFormat?          audioFormat;
  final String?               audioBitrate;
  final TrimSettings?         trimSettings;
  final ConvertSettings?      convertSettings;
  final SplitSettings?        splitSettings;
  final bool                  isVideo;

  const ProcessingScreen({
    super.key,
    required this.job,
    required this.label,
    required this.accentColor,
    this.settings,
    this.audioFormat,
    this.audioBitrate,
    this.trimSettings,
    this.convertSettings,
    this.splitSettings,
    this.isVideo = true,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late ProcessingJob _job;

  double   _progress  = 0;
  String   _statusMsg = 'Initializing…';
  DateTime? _startTime;
  Timer?   _timer;
  String _elapsed   = '0:00';
  String _remaining = '–';

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startProcessing());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    final provider = context.read<AppProvider>();
    _startTime = DateTime.now();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_startTime!);
      final m = elapsed.inMinutes;
      final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      String remaining = '–';
      if (_progress > 0.02) {
        final totalEst = elapsed.inSeconds / _progress;
        final remSec = (totalEst - elapsed.inSeconds).round();
        final rm = remSec ~/ 60;
        final rs = (remSec % 60).toString().padLeft(2, '0');
        remaining = '$rm:$rs left';
      }
      if (mounted) setState(() { _elapsed = '$m:$s'; _remaining = remaining; });
    });

    setState(() { _job.status = JobStatus.running; _statusMsg = widget.label; });
    provider.addJob(_job);

    void onProgress(double p) {
      if (mounted) setState(() { _progress = p; });
    }

    bool success = false;
    List<String> splitParts = [];

    try {
      switch (_job.jobType) {
        case JobType.compressVideo:
          success = await provider.ffmpeg.compressVideo(
            inputPath: _job.inputPath,
            outputPath: _job.outputPath,
            settings: widget.settings!,
            onProgress: onProgress,
          );
          break;
        case JobType.compressAudio:
          success = await provider.ffmpeg.compressAudio(
            inputPath: _job.inputPath,
            outputPath: _job.outputPath,
            bitrate: widget.audioBitrate ?? '128k',
            format: widget.audioFormat ?? AudioFormat.mp3,
            onProgress: onProgress,
          );
          break;
        case JobType.trimVideo:
          success = await provider.ffmpeg.trimVideo(
            inputPath: _job.inputPath,
            outputPath: _job.outputPath,
            trim: widget.trimSettings!,
            onProgress: onProgress,
          );
          break;
        case JobType.trimAudio:
          success = await provider.ffmpeg.trimAudio(
            inputPath: _job.inputPath,
            outputPath: _job.outputPath,
            trim: widget.trimSettings!,
            onProgress: onProgress,
          );
          break;
        case JobType.convertToAudio:
          success = await provider.ffmpeg.convertVideoToAudio(
            inputPath: _job.inputPath,
            outputPath: _job.outputPath,
            settings: widget.convertSettings!,
            onProgress: onProgress,
          );
          break;
        case JobType.splitVideo:
          final s = widget.splitSettings!;
          if (s.mode == SplitMode.equalParts) {
            splitParts = await provider.ffmpeg.splitVideoEqualParts(
              inputPath: _job.inputPath,
              outputDir: _job.outputPath,
              parts: s.value,
              onProgress: onProgress,
            );
          } else {
            splitParts = await provider.ffmpeg.splitVideoByTime(
              inputPath: _job.inputPath,
              outputDir: _job.outputPath,
              segmentSeconds: s.value,
              onProgress: onProgress,
            );
          }
          success = splitParts.isNotEmpty;
          break;
        case JobType.splitAudio:
  final s = widget.splitSettings!;
  if (s.mode == SplitMode.equalParts) {
    splitParts = await provider.ffmpeg.splitAudioEqualParts(
      inputPath: _job.inputPath,
      outputDir: _job.outputPath,
      parts: s.value,
      onProgress: onProgress,
    );
  } else {
    splitParts = await provider.ffmpeg.splitAudioByTime(
      inputPath: _job.inputPath,
      outputDir: _job.outputPath,
      segmentSeconds: s.value,
      onProgress: onProgress,
    );
  }
  success = splitParts.isNotEmpty;
  break;
      }
    } catch (e) {
      success = false;
      _job.errorMessage = e.toString();
    }

    _timer?.cancel();
    final processingTime = DateTime.now().difference(_startTime!);

    if (success) {
      final outSize = await provider.files.getFileSize(_job.outputPath);
      _job
        ..status = JobStatus.completed
        ..progress = 1.0
        ..outputSizeBytes = outSize
        ..processingTime = processingTime;
      setState(() { _progress = 1.0; _statusMsg = 'Done!'; });
      provider.updateJob(_job);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            job: _job,
            accentColor: widget.accentColor,
            splitParts: splitParts,
          ),
        ),
      );
    } else {
      _job
        ..status = JobStatus.failed
        ..processingTime = processingTime;
      setState(() { _statusMsg = 'Processing failed'; });
      provider.updateJob(_job);
    }
  }

  Future<void> _cancel() async {
    final provider = context.read<AppProvider>();
    await provider.ffmpeg.cancel();
    _timer?.cancel();
    _job.status = JobStatus.cancelled;
    provider.updateJob(_job);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pct    = (_progress * 100).toInt();
    final failed = _job.status == JobStatus.failed;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (failed ? AppTheme.red : widget.accentColor)
                          .withOpacity(0.1 + _pulseCtrl.value * 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: (failed ? AppTheme.red : widget.accentColor)
                              .withOpacity(0.2 + _pulseCtrl.value * 0.15),
                          blurRadius: 32 + _pulseCtrl.value * 16,
                        ),
                      ],
                    ),
                    child: Icon(
                      failed
                          ? Icons.error_outline_rounded
                          : _progress >= 1.0
                              ? Icons.check_rounded
                              : Icons.bolt_rounded,
                      color: failed ? AppTheme.red : widget.accentColor,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(_statusMsg,
                  style: GoogleFonts.syne(
                    fontSize: 22, fontWeight: FontWeight.w700,
                    color: failed ? AppTheme.red : AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('$_elapsed elapsed  ·  $_remaining',
                  style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 40),
                if (!failed) ...[
                  AnimatedProgressBar(
                    progress: _progress,
                    color: widget.accentColor,
                    height: 8,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _progress < 0.03 ? 'Starting FFmpeg…' : 'Processing',
                        style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppTheme.textMuted),
                      ),
                      Text('$pct%',
                        style: GoogleFonts.dmMono(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: widget.accentColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _StepIndicators(
                    progress: _progress,
                    color: widget.accentColor,
                  ),
                ],
                if (failed) ...[
                  const SizedBox(height: 20),
                  DarkCard(
                    borderColor: AppTheme.red.withOpacity(0.3),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                        color: AppTheme.red, size: 16),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        _job.errorMessage ??
                            'An unexpected error occurred. Check file format.',
                        style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppTheme.textSecondary),
                      )),
                    ]),
                  ),
                ],
                const Spacer(),
                if (failed)
                  GlowButton(
                    label: 'Go Back',
                    icon: Icons.arrow_back_rounded,
                    color: AppTheme.red,
                    onTap: () => Navigator.pop(context),
                  )
                else
                  OutlineButton2(
                    label: 'Cancel',
                    icon: Icons.close_rounded,
                    color: AppTheme.textSecondary,
                    onTap: _cancel,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicators extends StatelessWidget {
  final double progress;
  final Color color;

  const _StepIndicators({required this.progress, required this.color});

  static const _steps = [
    (0.0,  'Reading file'),
    (0.15, 'Building command'),
    (0.25, 'Processing'),
    (0.90, 'Saving output'),
    (1.0,  'Done'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _steps.map((s) {
        final threshold = s.$1;
        final label     = s.$2;
        final done   = progress >= threshold + 0.01;
        final active = !done && progress >= threshold - 0.1;
        final c = done
            ? color
            : active
                ? color.withOpacity(0.5)
                : AppTheme.textMuted;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: c, size: 16,
            ),
            const SizedBox(width: 10),
            Text(label,
              style: GoogleFonts.dmSans(fontSize: 13, color: c)),
          ]),
        );
      }).toList(),
    );
  }
}