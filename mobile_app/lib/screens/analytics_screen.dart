import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/database_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _studyMinutesWeek = 0;
  int _studyMinutesToday = 0;

  static const _primary = Color(0xFFD97706);
  static const _accent = Color(0xFF059669);
  static const _bg = Color(0xFFFFFBEB);

  @override
  void initState() {
    super.initState();
    _loadStudyStats();
  }

  Future<void> _loadStudyStats() async {
    final week = await DatabaseService.instance.getTotalStudyMinutes(days: 7);
    final today = await DatabaseService.instance.getTotalStudyMinutes(days: 1);
    setState(() {
      _studyMinutesWeek = week;
      _studyMinutesToday = today;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: _primary,
        elevation: 0,
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          final total = provider.tasks.length;
          final completed = provider.tasks.where((t) => t.completed).length;
          final rate = total == 0 ? 0.0 : (completed / total * 100);

          return RefreshIndicator(
            onRefresh: _loadStudyStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatGrid(context, completed, total, rate),
                  const SizedBox(height: 16),
                  _buildStudyStats(context),
                  const SizedBox(height: 16),
                  _buildWeeklyGoal(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, int completed, int total, double rate) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(title: 'Tasks Done', value: '$completed', icon: Icons.check_circle_rounded, color: _accent),
        _StatCard(title: 'Total Tasks', value: '$total', icon: Icons.list_alt_rounded, color: _primary),
        _StatCard(title: 'Completion', value: '${rate.toStringAsFixed(0)}%', icon: Icons.pie_chart_rounded, color: const Color(0xFF7C3AED)),
        _StatCard(title: 'Study Today', value: '${_studyMinutesToday}m', icon: Icons.timer_rounded, color: const Color(0xFFDC2626)),
      ],
    );
  }

  Widget _buildStudyStats(BuildContext context) {
    final hours = (_studyMinutesWeek / 60).toStringAsFixed(1);
    const weeklyTargetMin = 7 * 4 * 60;
    final progress = (_studyMinutesWeek / weeklyTargetMin).clamp(0.0, 1.0);
    final pct = (progress * 100).toInt();
    final onTrack = _studyMinutesWeek >= 240;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.school_rounded, color: _primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Study Time This Week',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: onTrack ? _accent.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  onTrack ? 'On Track' : 'Behind',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: onTrack ? _accent : Colors.orange[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('$hours hrs',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(onTrack ? 'Great progress this week!' : 'Target: 4 hrs/day',
              style: TextStyle(fontSize: 13, color: onTrack ? _accent : Colors.orange[700])),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(onTrack ? _accent : _primary),
            ),
          ),
          const SizedBox(height: 6),
          Text('$pct% of weekly goal (28 hrs)',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoal(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Week at a Glance',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _goalRow('Daily study goal (4 hrs)', _studyMinutesToday >= 240),
          _goalRow('Completed tasks today', context.read<TaskProvider>().completedToday > 0),
          _goalRow('Focus sessions logged', _studyMinutesWeek > 0),
          _goalRow('BCS prep this week', _studyMinutesWeek >= 60),
        ],
      ),
    );
  }

  Widget _goalRow(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: done ? _accent : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(done ? Icons.check : Icons.remove, size: 14, color: done ? Colors.white : Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: done ? const Color(0xFF0F172A) : Colors.grey[500]))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
              overflow: TextOverflow.ellipsis),
          Text(title,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
