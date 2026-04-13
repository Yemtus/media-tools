import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/media_file.dart';
import '../providers/app_provider.dart';
import '../widgets/shared_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (_, p, __) => p.history.isEmpty
                ? const SizedBox()
                : TextButton(
                    onPressed: () => _confirmClear(context, p),
                    child: Text('Clear', style: GoogleFonts.dmSans(
                      color: AppTheme.red, fontWeight: FontWeight.w600)),
                  ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final history = provider.history;
          if (history.isEmpty) {
            return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Icon(Icons.history_rounded,
                    color: AppTheme.textMuted, size: 32),
                ),
                const SizedBox(height: 20),
                Text('No jobs yet', style: GoogleFonts.syne(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
                const SizedBox(height: 6),
                Text('Processed files will appear here',
                  style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppTheme.textSecondary)),
              ],
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _HistoryCard(job: history[index]),
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear History', style: GoogleFonts.syne(
          fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        content: Text(
          'This removes all job history. Output files are not deleted.',
          style: GoogleFonts.dmSans(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(
              color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () { provider.clearHistory(); Navigator.pop(ctx); },
            child: Text('Clear', style: GoogleFonts.dmSans(
              color: AppTheme.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ProcessingJob job;
  const _HistoryCard({required this.job});

  Color get _statusColor {
    switch (job.status) {
      case JobStatus.completed:  return AppTheme.green;
      case JobStatus.failed:     return AppTheme.red;
      case JobStatus.cancelled:  return AppTheme.amber;
      default:                   return AppTheme.textMuted;
    }
  }

  Color get _accentColor {
    switch (job.jobType) {
      case JobType.compressVideo:  return AppTheme.videoColor;
      case JobType.compressAudio:  return AppTheme.audioColor;
      case JobType.trimVideo:
      case JobType.trimAudio:      return AppTheme.trimColor;
      case JobType.convertToAudio: return AppTheme.convertColor;
      case JobType.splitVideo:
      case JobType.splitAudio:     return AppTheme.splitColor;
    }
  }

  IconData get _jobIcon {
    switch (job.jobType) {
      case JobType.compressVideo:  return Icons.compress_rounded;
      case JobType.compressAudio:  return Icons.graphic_eq_rounded;
      case JobType.trimVideo:
      case JobType.trimAudio:      return Icons.content_cut_rounded;
      case JobType.convertToAudio: return Icons.music_note_rounded;
      case JobType.splitVideo:     return Icons.call_split_rounded;
      case JobType.splitAudio:     return Icons.queue_music_rounded;
    }
  }

  String _fmt(int b) {
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final filename = job.inputPath.split('/').last;
    return DarkCard(
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_jobIcon, color: _accentColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.jobType.label, style: GoogleFonts.syne(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(filename, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 12, color: AppTheme.textSecondary)),
            if (job.inputSizeBytes != null && job.outputSizeBytes != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Text(_fmt(job.inputSizeBytes!),
                  style: GoogleFonts.dmMono(
                    fontSize: 11, color: AppTheme.textMuted)),
                const Icon(Icons.arrow_forward_rounded,
                  size: 10, color: AppTheme.textMuted),
                Text(_fmt(job.outputSizeBytes!),
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: job.outputSizeBytes! < job.inputSizeBytes!
                        ? AppTheme.green : AppTheme.textMuted)),
              ]),
            ],
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(job.status.name, style: GoogleFonts.dmMono(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: _statusColor)),
        ),
      ]),
    );
  }
}