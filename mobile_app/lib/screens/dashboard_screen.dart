import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/xp_provider.dart';
import '../providers/task_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/focus_lock_provider.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'focus_lock_screen.dart';
import 'habits_screen.dart';
import 'analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int index)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> _heatmap = {};

  static const _blue = Color(0xFF2563EB);
  static const _bg = Color(0xFFF0F9FF);
  static const _fg = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduleDailyNotifications();
      await _loadHeatmap();
      await _checkAndAwardBadges();
    });
  }

  Future<void> _loadHeatmap() async {
    final data = await DatabaseService.instance.getStudyHeatmap(days: 105);
    if (mounted) setState(() => _heatmap = data);
  }

  void _scheduleDailyNotifications() {
    // Morning briefing at 7:00 AM
    NotificationService.instance.scheduleDailyNotification(
      id: 201,
      title: 'Good Morning! Time to plan your day',
      body: 'Open the app to get your AI morning briefing.',
      hour: 7,
      minute: 0,
    );
    // Evening review at 9:00 PM
    NotificationService.instance.scheduleDailyNotification(
      id: 202,
      title: 'Evening Check-in',
      body: 'How was your day? Log your progress and review.',
      hour: 21,
      minute: 0,
    );
    // BCS study reminder at 3:00 PM
    NotificationService.instance.scheduleDailyNotification(
      id: 203,
      title: 'BCS Study Reminder',
      body: 'Have you studied BCS topics today? Even 30 minutes counts!',
      hour: 15,
      minute: 0,
    );
  }

  Future<void> _checkAndAwardBadges() async {
    final xp = context.read<XpProvider>();
    final tasks = context.read<TaskProvider>();
    final habits = context.read<HabitProvider>();

    // First task completed
    if (tasks.tasks.any((t) => t.completed)) {
      await xp.awardBadge('first_task');
    }

    // 7-day habit streak
    if (habits.habits.any((h) => h.streak >= 7)) {
      await xp.awardBadge('streak_7');
    }

    // Level 5+
    if (xp.level >= 4) {
      await xp.awardBadge('level_5');
    }

    // 5+ pomodoros (inferred from XP)
    if (xp.xp >= XpRewards.pomodoroComplete * 5) {
      await xp.awardBadge('pomodoro_5');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good Day!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            Text('RUET EEE • BCS Candidate', style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        actions: [
          Consumer<XpProvider>(
            builder: (_, xp, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${xp.xp} XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildXpCard(context),
            const SizedBox(height: 14),
            _buildFocusLockBanner(context),
            const SizedBox(height: 14),
            _buildTodaySummary(context),
            const SizedBox(height: 14),
            _buildQuickActions(context),
            const SizedBox(height: 14),
            _buildHeatmap(context),
            const SizedBox(height: 14),
            _buildBadgesCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildXpCard(BuildContext context) {
    return Consumer<XpProvider>(
      builder: (_, xp, __) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${xp.level + 1}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(xp.levelName,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                  ],
                ),
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${xp.level + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${xp.xp} XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                Text('${xp.xpToNextLevel} to next level', style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: xp.levelProgress,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusLockBanner(BuildContext context) {
    return Consumer<FocusLockProvider>(
      builder: (_, provider, __) {
        if (!provider.anyActiveNow) return const SizedBox.shrink();
        final active = provider.activeLocks;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Focus Mode Active', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
                    Text('${active.map((l) => l.label).join(", ")} blocked now',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodaySummary(BuildContext context) {
    return Consumer2<TaskProvider, HabitProvider>(
      builder: (_, tasks, habits, __) {
        final completedTasks = tasks.completedToday;
        final totalTasks = tasks.todayTasks.length;
        final completedHabits = habits.completedToday;
        final totalHabits = habits.habits.length;

        return Row(
          children: [
            Expanded(child: _summaryTile('Tasks', '$completedTasks / $totalTasks', Icons.task_alt_rounded, _blue)),
            const SizedBox(width: 10),
            Expanded(child: _summaryTile('Habits', '$completedHabits / $totalHabits', Icons.repeat_rounded, const Color(0xFF059669))),
            const SizedBox(width: 10),
            Expanded(child: _summaryTile('Streak', '${habits.habits.isEmpty ? 0 : habits.habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b)} d', Icons.local_fire_department_rounded, Colors.orange)),
          ],
        );
      },
    );
  }

  Widget _summaryTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8)],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        Row(
          children: [
            _quickAction('Focus Timer', Icons.timer_rounded, const Color(0xFF7C3AED), () {
              widget.onNavigate?.call(2);
            }),
            const SizedBox(width: 10),
            _quickAction('Add Task', Icons.add_task_rounded, _blue, () {
              widget.onNavigate?.call(1);
            }),
            const SizedBox(width: 10),
            _quickAction('BCS Prep', Icons.menu_book_rounded, const Color(0xFF059669), () {
              widget.onNavigate?.call(3);
            }),
            const SizedBox(width: 10),
            _quickAction('Habits', Icons.repeat_rounded, Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HabitsScreen()));
            }),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _quickAction('AI Chat', Icons.smart_toy_rounded, const Color(0xFFD97706), () {
              widget.onNavigate?.call(4);
            }),
            const SizedBox(width: 10),
            _quickAction('Analytics', Icons.analytics_rounded, const Color(0xFF0EA5E9), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
            }),
            const SizedBox(width: 10),
            _quickAction('Focus Lock', Icons.lock_clock_rounded, const Color(0xFFDC2626), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FocusLockScreen()));
            }),
            const SizedBox(width: 10),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  Widget _quickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                  textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    final today = DateTime.now();
    const weeks = 15;
    const days = weeks * 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grid_on_rounded, color: _blue, size: 18),
              SizedBox(width: 8),
              Text('Study Activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _fg)),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(weeks, (w) {
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(
                    children: List.generate(7, (d) {
                      final dayIndex = w * 7 + d;
                      final date = today.subtract(Duration(days: days - 1 - dayIndex));
                      final isFuture = date.isAfter(today);
                      final dateKey = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
                      final minutes = _heatmap[dateKey] ?? 0;
                      final intensity = isFuture ? 0
                          : minutes == 0 ? 0
                          : minutes < 30 ? 1
                          : minutes < 60 ? 2
                          : 3;

                      final Color cellColor;
                      switch (intensity) {
                        case 1: cellColor = _blue.withValues(alpha: 0.25); break;
                        case 2: cellColor = _blue.withValues(alpha: 0.5); break;
                        case 3: cellColor = _blue; break;
                        default: cellColor = Colors.grey[100]!;
                      }

                      return Container(
                        width: 11, height: 11,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: isFuture ? Colors.transparent : cellColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Less', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              const SizedBox(width: 4),
              ...List.generate(4, (i) => Container(
                width: 10, height: 10,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: i == 0 ? Colors.grey[100] : _blue.withValues(alpha: 0.2 + i * 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const Text('More', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesCard(BuildContext context) {
    final allBadges = [
      ('first_task', 'First Task', Icons.task_alt_rounded, _blue),
      ('streak_7', '7-Day Streak', Icons.local_fire_department_rounded, Colors.orange),
      ('pomodoro_5', '5 Pomodoros', Icons.timer_rounded, const Color(0xFF7C3AED)),
      ('bcs_10', '10 BCS Topics', Icons.menu_book_rounded, const Color(0xFF059669)),
      ('level_5', 'Level 5', Icons.star_rounded, Colors.amber),
    ];

    return Consumer<XpProvider>(
      builder: (_, xp, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Text('Achievements', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _fg)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: allBadges.map((b) {
                final earned = xp.badges.contains(b.$1);
                return Column(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: earned ? b.$4.withValues(alpha: 0.12) : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(color: earned ? b.$4 : Colors.grey[300]!, width: 1.5),
                      ),
                      child: Icon(b.$3, color: earned ? b.$4 : Colors.grey[300], size: 24),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 58,
                      child: Text(b.$2,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                              color: earned ? _fg : Colors.grey[400]),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
