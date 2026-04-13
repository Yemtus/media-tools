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

class CompressAudioScreen extends StatefulWidget {
  const CompressAudioScreen({super.key});

  @override
  State<CompressAudioScreen> createState() => _CompressAudioScreenState();
}

class _CompressAudioScreenState extends State<CompressAudioScreen> {
  MediaFile? _file;
  bool _picking = false;
  bool _probing = false;
  AudioFormat _format  = AudioFormat.mp3;
  String      _bitrate = '128k';

  static const _bitrateOptions = ['64k', '96k', '128k', '192k', '256k', '320k'];
  static const _formatOptions  = [
    AudioFormat.mp3,
    AudioFormat.aac,
    AudioFormat.m4a,
    AudioFormat.ogg,
    AudioFormat.flac,
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Compress Audio'),
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
              accentColor: AppTheme.audioColor,
              icon: Icons.headphones_rounded,
              onPick: _pickFile,
            ),

            if (_file != null) ...[
              const SizedBox(height: 24),
              const SectionHeader(title: 'FILE INFO'),
              const SizedBox(height: 12),
              DarkCard(
                child: Column(children: [
                  _row('Size',     _file!.readableSize),
                  if (_file!.duration != null) _row('Duration', _file!.duration!),
                  if (_file!.codec    != null) _row('Codec',    _file!.codec!),
                  if (_file!.bitrate  != null) _row('Bitrate',  _file!.bitrate!),
                ]),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'OUTPUT FORMAT'),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _formatOptions.map((f) {
                  final sel = _format == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _format = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppTheme.audioColor.withOpacity(0.15) : AppTheme.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? AppTheme.audioColor : AppTheme.border,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(f.extension.toUpperCase(),
                          style: GoogleFonts.dmMono(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: sel ? AppTheme.audioColor : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList()),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'TARGET BITRATE'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _bitrateOptions.map((br) {
                  final sel = _bitrate == br;
                  return GestureDetector(
                    onTap: () => setState(() => _bitrate = br),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.audioColor.withOpacity(0.15) : AppTheme.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? AppTheme.audioColor : AppTheme.border,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Text(br,
                        style: GoogleFonts.dmMono(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: sel ? AppTheme.audioColor : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              GlowButton(
                label: 'Compress Audio',
                icon: Icons.compress_rounded,
                color: AppTheme.audioColor,
                onTap: () => _start(provider),
              ),
            ],

            if (_file == null) ...[
              const SizedBox(height: 40),
              const HowItWorks(steps: [
                'Select an audio file',
                'Choose output format and bitrate',
                'App re-encodes with FFmpeg',
                'Save compressed file',
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Text(l, style: GoogleFonts.dmSans(fontSize: 13, color: AppTheme.textSecondary)),
      const Spacer(),
      Text(v, style: GoogleFonts.dmMono(
        fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
    ]),
  );

  Future<void> _pickFile() async {
    final provider = context.read<AppProvider>();
    setState(() => _picking = true);
    try {
      final path = await provider.files.pickAudioFile();
      if (path == null) { setState(() => _picking = false); return; }
      setState(() { _picking = false; _probing = true; });
      final media = await provider.ffmpeg.probeFile(path);
      setState(() { _file = media; _probing = false; });
    } catch (_) {
      setState(() { _picking = false; _probing = false; });
      if (mounted) showErrorSnack(context, 'Failed to read file');
    }
  }

  Future<void> _start(AppProvider provider) async {
    if (_file == null) return;
    final outputPath = await provider.files.buildOutputPath(
      inputPath: _file!.path,
      suffix: 'compressed',
      extension: _format.extension,
    );
    final job = ProcessingJob(
      id: const Uuid().v4(),
      inputPath: _file!.path,
      outputPath: provider.files.resolveConflict(outputPath),
      jobType: JobType.compressAudio,
      inputSizeBytes: _file!.sizeBytes,
    );
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProcessingScreen(
        job: job,
        audioFormat: _format,
        audioBitrate: _bitrate,
        label: 'Compressing audio…',
        accentColor: AppTheme.audioColor,
      ),
    ));
  }
}