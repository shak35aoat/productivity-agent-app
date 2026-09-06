import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/xp_provider.dart';
import '../services/notification_service.dart';
import 'dart:math' as math;

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const _purple = Color(0xFF7C3AED);
  static const _green = Color(0xFF059669);
  static const _bg = Color(0xFFF0F9FF);

  final List<String> _subjects = [
    'General Study',
    'BCS - Bangla',
    'BCS - English',
    'BCS - Math',
    'BCS - General Knowledge',
    'EEE - Circuit Theory',
    'EEE - Electronics',
    'EEE - Power Systems',
    'Assignment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<PomodoroProvider>();
    provider.onFocusComplete = () {
      NotificationService.instance.showNotification(
        id: 101,
        title: 'Session done! +${XpRewards.pomodoroComplete} XP',
        body: 'Great work! Take a well-earned break.',
      );
      context.read<XpProvider>().addXp(XpRewards.pomodoroComplete);
    };
    provider.onBreakComplete = () {
      NotificationService.instance.showNotification(
        id: 102,
        title: 'Break over!',
        body: 'Ready for another focus session?',
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _purple,
        elevation: 0,
        title: const Text('Focus Timer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          Consumer<PomodoroProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: provider.isRunning ? null : provider.reset,
            ),
          ),
        ],
      ),
      body: Consumer<PomodoroProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                _buildSessionDots(provider),
                const SizedBox(height: 24),
                _buildSubjectSelector(provider),
                const SizedBox(height: 32),
                _buildTimerRing(provider),
                const SizedBox(height: 32),
                _buildControls(context, provider),
                const SizedBox(height: 24),
                _buildXpBadge(),
                const SizedBox(height: 16),
                _buildTipCard(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionDots(PomodoroProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(4, (i) {
          final filled = i < (provider.completedSessions % 4);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 12, height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? _purple : Colors.grey[200],
              border: Border.all(color: filled ? _purple : Colors.grey[300]!, width: 1.5),
            ),
          );
        }),
        const SizedBox(width: 12),
        Text(
          '${provider.completedSessions} sessions today',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSubjectSelector(PomodoroProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: provider.currentSubject,
        decoration: InputDecoration(
          labelText: 'Studying',
          prefixIcon: const Icon(Icons.book_rounded, color: _purple),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: provider.isRunning ? null : (v) => provider.setSubject(v!),
      ),
    );
  }

  Widget _buildTimerRing(PomodoroProvider provider) {
    final Color timerColor;
    final Color bgRingColor;
    switch (provider.state) {
      case PomodoroState.focusing:
        timerColor = _purple;
        bgRingColor = _purple.withValues(alpha: 0.08);
        break;
      case PomodoroState.onBreak:
        timerColor = _green;
        bgRingColor = _green.withValues(alpha: 0.08);
        break;
      case PomodoroState.longBreak:
        timerColor = const Color(0xFF0EA5E9);
        bgRingColor = const Color(0xFF0EA5E9).withValues(alpha: 0.08);
        break;
      case PomodoroState.idle:
        timerColor = Colors.grey;
        bgRingColor = Colors.grey.withValues(alpha: 0.05);
        break;
    }

    return Container(
      width: 260, height: 260,
      decoration: BoxDecoration(color: bgRingColor, shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(260, 260),
            painter: _TimerPainter(
              progress: provider.progress,
              color: timerColor,
              backgroundColor: Colors.grey[200]!,
              strokeWidth: 12,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.formattedTime,
                style: TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.w800,
                  color: timerColor,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  provider.stateLabel,
                  style: TextStyle(color: timerColor, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, PomodoroProvider provider) {
    if (provider.state == PomodoroState.idle) {
      return SizedBox(
        width: 220,
        height: 54,
        child: FilledButton.icon(
          onPressed: provider.start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Focus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor: _purple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (provider.state == PomodoroState.focusing) ...[
          OutlinedButton.icon(
            onPressed: provider.skipToBreak,
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Skip'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _purple),
              foregroundColor: _purple,
              minimumSize: const Size(100, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(width: 14),
        ],
        FilledButton.icon(
          onPressed: provider.isRunning ? provider.pause : provider.resume,
          icon: Icon(provider.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
          label: Text(provider.isRunning ? 'Pause' : 'Resume',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor: _purple,
            minimumSize: const Size(140, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ],
    );
  }

  Widget _buildXpBadge() {
    return Consumer<XpProvider>(
      builder: (_, xp, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 6),
            Text(
              'Complete session → +${XpRewards.pomodoroComplete} XP  •  ${xp.xp} total',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(PomodoroProvider provider) {
    final tips = {
      PomodoroState.idle: ('Close social media. One subject at a time.', Icons.lightbulb_rounded, Colors.amber),
      PomodoroState.focusing: ('Phone face-down. You are in the zone!', Icons.do_not_disturb_on_rounded, _purple),
      PomodoroState.onBreak: ('Stand up, stretch, drink water. No scrolling!', Icons.self_improvement_rounded, _green),
      PomodoroState.longBreak: ('Eat something. Walk around. You earned it.', Icons.emoji_events_rounded, const Color(0xFF0EA5E9)),
    };

    final tip = tips[provider.state]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tip.$3.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: tip.$3.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(tip.$2, color: tip.$3, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(tip.$1, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
        ],
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _TimerPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_TimerPainter old) => old.progress != progress || old.color != color;
}
