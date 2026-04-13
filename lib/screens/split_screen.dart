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

class SplitScreen extends StatefulWidget {
  final bool isVideo;
  const SplitScreen({super.key, required this.isVideo});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  MediaFile? _file;
  bool _picking = false, _probing = false;
  SplitMode _mode = SplitMode.byTime;
  final _valueCtrl = TextEditingController(text: '60');
  late Color _color;
  late IconData _icon;

  @override
  void initState() {
    super.initState();
    _color = widget.isVideo ? AppTheme.splitColor : const Color(0xFFF97316);
    _icon  = widget.isVideo ? Icons.videocam_rounded : Icons.headphones_rounded;
  }

  @override
  void dispose() { _valueCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text('Split ${widget.isVideo ? "Video" : "Audio"}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilePickArea(
              file: _file,
              isLoading: _picking || _probing,
              accentColor: _color,
              icon: _icon,
              onPick: _pickFile,
            ),

            if (_file != null) ...[
              const SizedBox(height: 24),
              DarkCard(
                child: Row(children: [
                  InfoChip(
                      icon: Icons.storage_rounded,
                      label: _file!.readableSize,
                      color: _color),
                  const SizedBox(width: 8),
                  if (_file!.duration != null)
                    InfoChip(
                        icon: Icons.timer_rounded,
                        label: _file!.duration!,
                        color: AppTheme.textSecondary),
                ]),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'SPLIT METHOD'),
              const SizedBox(height: 12),
              Column(children: [
                _ModeRow(
                  label: 'By Duration',
                  description: 'Split every N seconds',
                  icon: Icons.timer_rounded,
                  selected: _mode == SplitMode.byTime,
                  color: _color,
                  onTap: () => setState(() {
                    _mode = SplitMode.byTime;
                    _valueCtrl.text = '60';
                  }),
                ),
                const SizedBox(height: 8),
                _ModeRow(
                  label: 'Equal Parts',
                  description: 'Split into N equal pieces',
                  icon: Icons.call_split_rounded,
                  selected: _mode == SplitMode.equalParts,
                  color: _color,
                  onTap: () => setState(() {
                    _mode = SplitMode.equalParts;
                    _valueCtrl.text = '3';
                  }),
                ),
              ]),
              const SizedBox(height: 24),
              const SectionHeader(title: 'VALUE'),
              const SizedBox(height: 12),
              DarkCard(
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _valueCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.dmMono(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Text(
                    _mode == SplitMode.byTime ? 'seconds' : 'parts',
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppTheme.textSecondary),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              if (_mode == SplitMode.byTime)
                Wrap(
                  spacing: 8,
                  children: ['30', '60', '120', '300', '600'].map((v) =>
                    _QuickChip(
                      label: '${v}s',
                      color: _color,
                      onTap: () => setState(() => _valueCtrl.text = v),
                    ),
                  ).toList(),
                ),
              if (_mode == SplitMode.equalParts)
                Wrap(
                  spacing: 8,
                  children: ['2', '3', '4', '5', '10'].map((v) =>
                    _QuickChip(
                      label: '${v}p',
                      color: _color,
                      onTap: () => setState(() => _valueCtrl.text = v),
                    ),
                  ).toList(),
                ),
              const SizedBox(height: 32),
              GlowButton(
                label: 'Split ${widget.isVideo ? "Video" : "Audio"}',
                icon: Icons.call_split_rounded,
                color: _color,
                onTap: () => _start(provider),
              ),
            ],

            if (_file == null) ...[
              const SizedBox(height: 40),
              HowItWorks( steps: [
                'Select a ${widget.isVideo ? "video" : "audio"} file',
                'Choose split method and value',
                'FFmpeg segments the file',
                'All parts saved to MediaTools folder',
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final provider = context.read<AppProvider>();
    setState(() => _picking = true);
    try {
      final path = widget.isVideo
          ? await provider.files.pickVideoFile()
          : await provider.files.pickAudioFile();
      if (path == null) { setState(() => _picking = false); return; }
      setState(() { _picking = false; _probing = true; });
      final media = await provider.ffmpeg.probeFile(path);
      setState(() { _file = media; _probing = false; });
    } catch (_) {
      setState(() { _picking = false; _probing = false; });
    }
  }

  Future<void> _start(AppProvider provider) async {
    if (_file == null) return;
    final value = int.tryParse(_valueCtrl.text);
    if (value == null || value < 1) {
      showErrorSnack(context, 'Enter a valid number');
      return;
    }
    final settings = SplitSettings(mode: _mode, value: value);
    final outputPath = await provider.files.getOutputDir();
    final job = ProcessingJob(
      id: const Uuid().v4(),
      inputPath: _file!.path,
      outputPath: outputPath,
      jobType: widget.isVideo ? JobType.splitVideo : JobType.splitAudio,
      inputSizeBytes: _file!.sizeBytes,
    );
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProcessingScreen(
        job: job,
        splitSettings: settings,
        isVideo: widget.isVideo,
        label: 'Splitting file…',
        accentColor: _color,
      ),
    ));
  }
}

class _ModeRow extends StatelessWidget {
  final String label, description;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeRow({
    required this.label, required this.description,
    required this.icon, required this.selected,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.1) : AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? color : AppTheme.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.15)
                : AppTheme.border.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: selected ? color : AppTheme.textMuted, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.syne(
              fontWeight: FontWeight.w700, fontSize: 14,
              color: selected ? color : AppTheme.textPrimary,
            )),
            Text(description, style: GoogleFonts.dmSans(
              fontSize: 12, color: AppTheme.textSecondary,
            )),
          ],
        )),
        if (selected)
          Icon(Icons.check_circle_rounded, color: color, size: 18),
      ]),
    ),
  );
}

class _QuickChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label, style: GoogleFonts.dmMono(
        fontSize: 12, color: color, fontWeight: FontWeight.w600,
      )),
    ),
  );
}