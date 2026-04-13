import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import 'compress_video_screen.dart';
import 'compress_audio_screen.dart';
import 'trim_screen.dart';
import 'convert_screen.dart';
import 'split_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: AppTheme.accent.withOpacity(0.4),
                              blurRadius: 16, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const HistoryScreen())),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Icon(Icons.history_rounded,
                            color: AppTheme.textSecondary, size: 20),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 28),
                    Text('Media\nTools',
                      style: GoogleFonts.syne(
                        fontSize: 42, fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary, height: 1.0, letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('FFmpeg-powered processing.\nFast, lossless, offline.',
                      style: GoogleFonts.dmSans(
                        fontSize: 15, color: AppTheme.textSecondary, height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Text('TOOLS', style: GoogleFonts.syne(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted, letterSpacing: 2,
                )),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  _FeatureCard(
                    title: 'Compress\nVideo',
                    icon: Icons.compress_rounded,
                    color: AppTheme.videoColor,
                    description: 'Reduce file size',
                    onTap: () => _push(context, const CompressVideoScreen()),
                  ),
                  _FeatureCard(
                    title: 'Compress\nAudio',
                    icon: Icons.graphic_eq_rounded,
                    color: AppTheme.audioColor,
                    description: 'Smaller audio files',
                    onTap: () => _push(context, const CompressAudioScreen()),
                  ),
                  _FeatureCard(
                    title: 'Trim\nMedia',
                    icon: Icons.content_cut_rounded,
                    color: AppTheme.trimColor,
                    description: 'Cut video & audio',
                    onTap: () => _push(context, const TrimScreen()),
                  ),
                  _FeatureCard(
                    title: 'Convert\nto Audio',
                    icon: Icons.music_note_rounded,
                    color: AppTheme.convertColor,
                    description: 'Extract audio track',
                    onTap: () => _push(context, const ConvertScreen()),
                  ),
                  _FeatureCard(
                    title: 'Split\nVideo',
                    icon: Icons.call_split_rounded,
                    color: AppTheme.splitColor,
                    description: 'Divide into parts',
                    onTap: () => _push(context, const SplitScreen(isVideo: true)),
                  ),
                  _FeatureCard(
                    title: 'Split\nAudio',
                    icon: Icons.queue_music_rounded,
                    color: const Color(0xFFF97316),
                    description: 'Segment audio file',
                    onTap: () => _push(context, const SplitScreen(isVideo: false)),
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accent.withOpacity(0.15),
                        AppTheme.accentLight.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.lightbulb_rounded, color: AppTheme.accentLight, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All processing happens on-device. Your files never leave your phone.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppTheme.accentLight, height: 1.4,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, _slideRoute(screen));
  }

  Route _slideRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (_, a, __) => screen,
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 320),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const Spacer(),
              Text(widget.title,
                style: GoogleFonts.syne(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary, height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(widget.description,
                style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}