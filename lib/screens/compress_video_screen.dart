import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../theme.dart';
import '../models/media_file.dart';
import '../providers/app_provider.dart';
import '../widgets/shared_widgets.dart';
import 'processing_screen.dart';

class CompressVideoScreen extends StatefulWidget {
  const CompressVideoScreen({super.key});

  @override
  State<CompressVideoScreen> createState() => _CompressVideoScreenState();
}

class _CompressVideoScreenState extends State<CompressVideoScreen> {
  MediaFile? _file;
  CompressionQuality _quality = CompressionQuality.balanced;
  bool _picking = false;
  bool _probing = false;

  CompressionSettings get _settings {
    switch (_quality) {
      case CompressionQuality.low:      return CompressionSettings.lowSize;
      case CompressionQuality.balanced: return CompressionSettings.balanced;
      case CompressionQuality.high:     return CompressionSettings.highQuality;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Compress Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.videoColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('MP4 · H.264',
              style: GoogleFonts.dmMono(fontSize: 11, color: AppTheme.videoColor),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilePickArea(
              file: _file,
              isLoading: _picking || _probing,
              accentColor: AppTheme.videoColor,
              icon: Icons.videocam_rounded,
              onPick: _pickFile,
            ),
            if (_file != null) ...[
              const SizedBox(height: 24),
              const SectionHeader(title: 'FILE INFO'),
              const SizedBox(height: 12),
              DarkCard(
                child: Column(children: [
                  InfoRow('Size', _file!.readableSize),
                  if (_file!.duration   != null) InfoRow('Duration',   _file!.duration!),
                  if (_file!.resolution != null) InfoRow('Resolution', _file!.resolution!),
                  if (_file!.codec      != null) InfoRow('Codec',      _file!.codec!),
                  if (_file!.bitrate    != null) InfoRow('Bitrate',    _file!.bitrate!),
                ]),
              ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'COMPRESSION LEVEL'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: QualityChip(
                  label: 'Low Size',
                  description: '480p · 500 kbps',
                  icon: Icons.compress_rounded,
                  color: AppTheme.red,
                  selected: _quality == CompressionQuality.low,
                  onTap: () => setState(() => _quality = CompressionQuality.low),
                )),
                const SizedBox(width: 10),
                Expanded(child: QualityChip(
                  label: 'Balanced',
                  description: '720p · 1.5 Mbps',
                  icon: Icons.tune_rounded,
                  color: AppTheme.amber,
                  selected: _quality == CompressionQuality.balanced,
                  onTap: () => setState(() => _quality = CompressionQuality.balanced),
                )),
                const SizedBox(width: 10),
                Expanded(child: QualityChip(
                  label: 'High',
                  description: '1080p · 3 Mbps',
                  icon: Icons.hd_rounded,
                  color: AppTheme.green,
                  selected: _quality == CompressionQuality.high,
                  onTap: () => setState(() => _quality = CompressionQuality.high),
                )),
              ]),
              const SizedBox(height: 32),
              GlowButton(
                label: 'Compress Video',
                icon: Icons.compress_rounded,
                color: AppTheme.videoColor,
                onTap: () => _startCompression(provider),
              ),
            ],
            if (_file == null) ...[
              const SizedBox(height: 40),
              const HowItWorks(steps: [
                'Pick a video file from storage',
                'Choose compression quality',
                'App runs FFmpeg processing',
                'See original vs new file size',
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
      final path = await provider.files.pickVideoFile();
      if (path == null) { setState(() => _picking = false); return; }
      setState(() { _picking = false; _probing = true; });
      final media = await provider.ffmpeg.probeFile(path);
      setState(() { _file = media; _probing = false; });
    } catch (e) {
      setState(() { _picking = false; _probing = false; });
      if (mounted) showErrorSnack(context, 'Failed to read file');
    }
  }

  Future<void> _startCompression(AppProvider provider) async {
    if (_file == null) return;
    final outputPath = await provider.files.buildOutputPath(
      inputPath: _file!.path,
      suffix: 'compressed',
      extension: 'mp4',
    );
    final job = ProcessingJob(
      id: const Uuid().v4(),
      inputPath: _file!.path,
      outputPath: provider.files.resolveConflict(outputPath),
      jobType: JobType.compressVideo,
      inputSizeBytes: _file!.sizeBytes,
    );
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProcessingScreen(
        job: job,
        settings: _settings,
        label: 'Compressing video…',
        accentColor: AppTheme.videoColor,
      ),
    ));
  }
}

class FilePickArea extends StatelessWidget {
  final MediaFile? file;
  final bool isLoading;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onPick;

  const FilePickArea({
    super.key,
    required this.file,
    required this.isLoading,
    required this.accentColor,
    required this.icon,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 130,
        decoration: BoxDecoration(
          color: file != null ? accentColor.withOpacity(0.08) : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: file != null ? accentColor.withOpacity(0.4) : AppTheme.border,
            width: file != null ? 1.5 : 1,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(
                color: accentColor, strokeWidth: 2))
            : file != null
                ? FileSelected(file: file!, color: accentColor,
                    icon: icon, onTap: onPick)
                : PickPrompt(color: accentColor, icon: icon),
      ),
    );
  }
}

class PickPrompt extends StatelessWidget {
  final Color color;
  final IconData icon;
  const PickPrompt({super.key, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 10),
      Text('Tap to select file',
        style: GoogleFonts.syne(fontWeight: FontWeight.w600,
          fontSize: 14, color: AppTheme.textPrimary),
      ),
      const SizedBox(height: 4),
      Text('MP4, MKV, MOV, AVI supported',
        style: GoogleFonts.dmSans(fontSize: 12, color: AppTheme.textMuted),
      ),
    ],
  );
}

class FileSelected extends StatelessWidget {
  final MediaFile file;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const FileSelected({
    super.key,
    required this.file,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(file.name, overflow: TextOverflow.ellipsis, maxLines: 1,
            style: GoogleFonts.syne(fontWeight: FontWeight.w700,
              fontSize: 14, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            InfoChip(icon: Icons.storage_rounded,
              label: file.readableSize, color: color),
            if (file.duration != null)
              InfoChip(icon: Icons.timer_rounded,
                label: file.duration!, color: AppTheme.textSecondary),
          ]),
        ],
      )),
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.border,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.swap_horiz_rounded,
            color: AppTheme.textSecondary, size: 16),
        ),
      ),
    ]),
  );
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(label, style: GoogleFonts.dmSans(
        fontSize: 13, color: AppTheme.textSecondary)),
      const Spacer(),
      Text(value, style: GoogleFonts.dmMono(
        fontSize: 13, color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500)),
    ]),
  );
}

class HowItWorks extends StatelessWidget {
  final List<String> steps;
  const HowItWorks({super.key, required this.steps});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('HOW IT WORKS', style: GoogleFonts.syne(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: AppTheme.textMuted, letterSpacing: 2,
      )),
      const SizedBox(height: 12),
      ...steps.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: Center(child: Text('${e.key + 1}',
              style: GoogleFonts.syne(fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(e.value,
            style: GoogleFonts.dmSans(
              fontSize: 13, color: AppTheme.textSecondary),
          )),
        ]),
      )),
    ],
  );
}