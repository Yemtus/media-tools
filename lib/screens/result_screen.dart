import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../models/media_file.dart';
import '../widgets/shared_widgets.dart';

class ResultScreen extends StatelessWidget {
  final ProcessingJob job;
  final Color accentColor;
  final List<String> splitParts;

  const ResultScreen({
    super.key,
    required this.job,
    required this.accentColor,
    this.splitParts = const [],
  });

  bool get isSplit =>
      job.jobType == JobType.splitVideo || job.jobType == JobType.splitAudio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withOpacity(0.12),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.3),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: Icon(Icons.check_rounded, color: accentColor, size: 44),
                  ),
                  const SizedBox(height: 20),
                  Text('Complete!',
                    style: GoogleFonts.syne(
                      fontSize: 30, fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(job.jobType.label,
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  if (job.processingTime != null)
                    Text(
                      'Finished in ${_formatDuration(job.processingTime!)}',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppTheme.textMuted),
                    ),
                ]),
              ),

              const SizedBox(height: 36),

              if (!isSplit &&
                  job.inputSizeBytes != null &&
                  job.outputSizeBytes != null) ...[
                const SectionHeader(title: 'SIZE COMPARISON'),
                const SizedBox(height: 12),
                _SizeComparison(
                  inputBytes: job.inputSizeBytes!,
                  outputBytes: job.outputSizeBytes!,
                  ratio: job.compressionRatio,
                  color: accentColor,
                  saved: job.savedSizeReadable,
                ),
                const SizedBox(height: 28),
              ],

              if (isSplit && splitParts.isNotEmpty) ...[
                SectionHeader(title: '${splitParts.length} PARTS CREATED'),
                const SizedBox(height: 12),
                ...splitParts.asMap().entries.map((e) {
                  final size = File(e.value).existsSync()
                      ? File(e.value).lengthSync()
                      : 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DarkCard(
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text('${e.key + 1}',
                            style: GoogleFonts.syne(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.split('/').last,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            Text(_formatBytes(size),
                              style: GoogleFonts.dmMono(
                                  fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        )),
                        const Icon(Icons.check_circle_rounded,
                            color: AppTheme.green, size: 16),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],

              const SectionHeader(title: 'SAVED TO'),
              const SizedBox(height: 12),
              DarkCard(
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.folder_rounded, color: accentColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    isSplit
                        ? job.outputPath
                        : job.outputPath.split('/').last,
                    style: GoogleFonts.dmMono(
                        fontSize: 12, color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  )),
                ]),
              ),

              const SizedBox(height: 40),

              GlowButton(
                label: 'Done',
                icon: Icons.home_rounded,
                color: accentColor,
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
              const SizedBox(height: 12),
              OutlineButton2(
                label: 'Process Another File',
                icon: Icons.add_rounded,
                color: accentColor,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _SizeComparison extends StatelessWidget {
  final int inputBytes, outputBytes;
  final double ratio;
  final String saved;
  final Color color;

  const _SizeComparison({
    required this.inputBytes, required this.outputBytes,
    required this.ratio, required this.saved, required this.color,
  });

  String _fmt(int b) {
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    if (b < 1024 * 1024 * 1024) {
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final reduced  = outputBytes < inputBytes;
    final pctSaved = (ratio * 100).toInt();

    return DarkCard(
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            LayoutBuilder(builder: (ctx, c) {
              final newWidth = reduced
                  ? c.maxWidth * (outputBytes / inputBytes).clamp(0.0, 1.0)
                  : c.maxWidth;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                height: 10,
                width: newWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                  ),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)
                  ],
                ),
              );
            }),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: Column(children: [
            Text('ORIGINAL', style: GoogleFonts.syne(
                fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(_fmt(inputBytes), style: GoogleFonts.syne(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
          ])),
          Icon(Icons.arrow_forward_rounded,
              color: reduced ? color : AppTheme.red, size: 20),
          Expanded(child: Column(children: [
            Text('OUTPUT', style: GoogleFonts.syne(
                fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(_fmt(outputBytes), style: GoogleFonts.syne(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: reduced ? color : AppTheme.red)),
          ])),
        ]),
        const SizedBox(height: 16),
        Divider(color: AppTheme.border),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: reduced
                ? AppTheme.green.withOpacity(0.1)
                : AppTheme.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              reduced
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
              color: reduced ? AppTheme.green : AppTheme.red, size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              reduced
                  ? 'Saved $saved ($pctSaved% smaller)'
                  : 'File grew by $saved',
              style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: reduced ? AppTheme.green : AppTheme.red,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}