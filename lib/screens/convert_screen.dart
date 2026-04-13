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

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  MediaFile? _file;
  bool _picking = false, _probing = false;
  AudioFormat _format = AudioFormat.mp3;
  String _bitrate = '192k';

  static const _formats = [
    (AudioFormat.mp3,  'MP3',  'Most compatible'),
    (AudioFormat.aac,  'AAC',  'Efficient · iOS'),
    (AudioFormat.m4a,  'M4A',  'Apple format'),
    (AudioFormat.wav,  'WAV',  'Lossless · large'),
    (AudioFormat.ogg,  'OGG',  'Open source'),
    (AudioFormat.flac, 'FLAC', 'Lossless'),
  ];

  static const _bitrateOptions = ['96k', '128k', '192k', '256k', '320k'];

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Convert to Audio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.convertColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Video → Audio',
              style: GoogleFonts.dmMono(fontSize: 11, color: AppTheme.convertColor),
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
              accentColor: AppTheme.convertColor,
              icon: Icons.videocam_rounded,
              onPick: _pickFile,
            ),

            if (_file != null) ...[
              const SizedBox(height: 28),
              const SectionHeader(title: 'OUTPUT FORMAT'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: _formats.map((record) {
                  final f     = record.$1;
                  final label = record.$2;
                  final desc  = record.$3;
                  final sel   = _format == f;
                  return GestureDetector(
                    onTap: () => setState(() => _format = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.convertColor.withOpacity(0.12)
                            : AppTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? AppTheme.convertColor : AppTheme.border,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(label,
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w700, fontSize: 14,
                              color: sel
                                  ? AppTheme.convertColor
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(desc,
                            style: GoogleFonts.dmSans(
                              fontSize: 10, color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_format != AudioFormat.wav && _format != AudioFormat.flac) ...[
                const SizedBox(height: 24),
                const SectionHeader(title: 'AUDIO BITRATE'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _bitrateOptions.map((br) {
                    final sel = _bitrate == br;
                    return GestureDetector(
                      onTap: () => setState(() => _bitrate = br),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.convertColor.withOpacity(0.12)
                              : AppTheme.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? AppTheme.convertColor : AppTheme.border,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(br,
                          style: GoogleFonts.dmMono(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: sel
                                ? AppTheme.convertColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 32),
              GlowButton(
                label: 'Extract Audio',
                icon: Icons.music_note_rounded,
                color: AppTheme.convertColor,
                onTap: () => _start(provider),
              ),
            ],

            if (_file == null) ...[
              const SizedBox(height: 40),
              const HowItWorks(steps: [
                'Pick any video file',
                'Choose audio output format',
                'FFmpeg strips video track',
                'Saves clean audio file',
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
    } catch (_) {
      setState(() { _picking = false; _probing = false; });
    }
  }

  Future<void> _start(AppProvider provider) async {
    if (_file == null) return;
    final settings = ConvertSettings(
        outputFormat: _format, audioBitrate: _bitrate);
    final outputPath = await provider.files.buildOutputPath(
      inputPath: _file!.path,
      suffix: 'audio',
      extension: _format.extension,
    );
    final job = ProcessingJob(
      id: const Uuid().v4(),
      inputPath: _file!.path,
      outputPath: provider.files.resolveConflict(outputPath),
      jobType: JobType.convertToAudio,
      inputSizeBytes: _file!.sizeBytes,
    );
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProcessingScreen(
        job: job,
        convertSettings: settings,
        label: 'Extracting audio…',
        accentColor: AppTheme.convertColor,
      ),
    ));
  }
}