import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme.dart';
import '../models/media_file.dart';
import '../providers/app_provider.dart';
import '../widgets/shared_widgets.dart';
import 'compress_video_screen.dart';
import 'processing_screen.dart';

class TrimScreen extends StatefulWidget {
  const TrimScreen({super.key});

  @override
  State<TrimScreen> createState() => _TrimScreenState();
}

class _TrimScreenState extends State<TrimScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  MediaFile? _file;
  bool _picking = false;
  bool _probing = false;
  final _startCtrl = TextEditingController(text: '00:00:00');
  final _endCtrl   = TextEditingController(text: '00:00:00');
  bool _isVideo = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _isVideo = _tabs.index == 0));
  }

  @override
  void dispose() {
    _tabs.dispose(); _startCtrl.dispose(); _endCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final color = _isVideo ? AppTheme.trimColor : AppTheme.audioColor;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Trim Media'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: color,
          labelColor: color,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.syne(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [Tab(text: 'Video'), Tab(text: 'Audio')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildContent(provider, true),
          _buildContent(provider, false),
        ],
      ),
    );
  }

  Widget _buildContent(AppProvider provider, bool isVideo) {
    final color = isVideo ? AppTheme.trimColor : AppTheme.audioColor;
    final icon  = isVideo ? Icons.videocam_rounded : Icons.headphones_rounded;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilePickArea(
            file: _file,
            isLoading: _picking || _probing,
            accentColor: color,
            icon: icon,
            onPick: () => _pickFile(isVideo),
          ),

          if (_file != null &&
              _file!.type == (isVideo ? MediaType.video : MediaType.audio)) ...[
            const SizedBox(height: 24),
            if (_file!.duration != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(children: [
                  Icon(Icons.timer_outlined, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text('Total duration: ${_file!.duration}',
                    style: GoogleFonts.dmMono(fontSize: 13, color: color),
                  ),
                ]),
              ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'TRIM RANGE'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TimeInputField(
                label: 'Start Time',
                controller: _startCtrl,
                hint: '00:00:00',
              )),
              const SizedBox(width: 16),
              Expanded(child: TimeInputField(
                label: 'End Time',
                controller: _endCtrl,
                hint: '00:01:00',
              )),
            ]),
            const SizedBox(height: 12),
            DarkCard(
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                  color: AppTheme.textMuted, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use format HH:MM:SS. Example: 00:01:30 = 1 min 30 sec',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 32),
            GlowButton(
              label: isVideo ? 'Trim Video' : 'Trim Audio',
              icon: Icons.content_cut_rounded,
              color: color,
              onTap: () => _start(provider, isVideo),
            ),
          ],

          if (_file == null) ...[
            const SizedBox(height: 40),
            HowItWorks(steps: [
              'Select a ${isVideo ? "video" : "audio"} file',
              'Set start and end times',
              'App cuts that exact segment',
              'Saves trimmed file instantly',
            ]),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFile(bool isVideo) async {
    final provider = context.read<AppProvider>();
    setState(() { _picking = true; _file = null; });
    try {
      final path = isVideo
          ? await provider.files.pickVideoFile()
          : await provider.files.pickAudioFile();
      if (path == null) { setState(() => _picking = false); return; }
      setState(() { _picking = false; _probing = true; });
      final media = await provider.ffmpeg.probeFile(path);
      if (media?.duration != null) {
        _endCtrl.text = _normalizeDuration(media!.duration!);
      }
      setState(() { _file = media; _probing = false; });
    } catch (_) {
      setState(() { _picking = false; _probing = false; });
      if (mounted) showErrorSnack(context, 'Failed to read file');
    }
  }

  String _normalizeDuration(String d) {
    final parts = d.split(':');
    if (parts.length == 2) return '00:$d';
    if (parts.length == 3) return d;
    return '00:00:00';
  }

  Future<void> _start(AppProvider provider, bool isVideo) async {
    if (_file == null) return;
    final trim = _parseTrim();
    if (trim == null) {
      showErrorSnack(context, 'Invalid time format. Use HH:MM:SS');
      return;
    }
    if (trim.endTime <= trim.startTime) {
      showErrorSnack(context, 'End time must be after start time');
      return;
    }
    final ext = isVideo ? 'mp4' : _file!.name.split('.').last;
    final outputPath = await provider.files.buildOutputPath(
      inputPath: _file!.path,
      suffix: 'trimmed',
      extension: ext,
    );
    final job = ProcessingJob(
      id: const Uuid().v4(),
      inputPath: _file!.path,
      outputPath: provider.files.resolveConflict(outputPath),
      jobType: isVideo ? JobType.trimVideo : JobType.trimAudio,
      inputSizeBytes: _file!.sizeBytes,
    );
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProcessingScreen(
        job: job,
        trimSettings: trim,
        label: isVideo ? 'Trimming video…' : 'Trimming audio…',
        accentColor: isVideo ? AppTheme.trimColor : AppTheme.audioColor,
      ),
    ));
  }

  TrimSettings? _parseTrim() {
    final start = _parseTime(_startCtrl.text);
    final end   = _parseTime(_endCtrl.text);
    if (start == null || end == null) return null;
    return TrimSettings(startTime: start, endTime: end);
  }

  Duration? _parseTime(String text) {
    try {
      final parts = text.trim().split(':').map(int.parse).toList();
      if (parts.length == 3) {
        return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
      } else if (parts.length == 2) {
        return Duration(minutes: parts[0], seconds: parts[1]);
      }
    } catch (_) {}
    return null;
  }
}