import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/xp_provider.dart';
import '../models/habit_model.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  static const _green = Color(0xFF059669);
  static const _bg = Color(0xFFF0F9FF);
  static const _fg = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().loadHabits();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _completeHabit(BuildContext context, String id) async {
    final provider = context.read<HabitProvider>();
    final xpProvider = context.read<XpProvider>();
    await provider.completeHabit(id);
    await xpProvider.addXp(XpRewards.habitComplete);
    if (provider.habits.every((h) => h.isCompletedToday)) {
      await xpProvider.addXp(50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _green,
        elevation: 0,
        title: const Text('Daily Habits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => _showAddHabitDialog(context),
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
            builder: (context, provider, _) {
              if (provider.loading) {
                return const Center(child: CircularProgressIndicator(color: _green));
              }
              return Column(
                children: [
                  _buildHeader(context, provider),
                  if (provider.streaksAtRisk > 0) _buildStreakWarning(provider),
                  if (provider.habits.isEmpty)
                    _buildEmptyState(context)
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: provider.habits.length,
                        itemBuilder: (context, index) =>
                            _HabitCard(habit: provider.habits[index], onComplete: _completeHabit),
                      ),
                    ),
                ],
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        backgroundColor: _green,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HabitProvider provider) {
    final done = provider.completedToday;
    final total = provider.habits.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF047857), Color(0xFF10B981)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
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
                  const Text("Today's Habits", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('$done / $total completed',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                ],
              ),
              if (progress == 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('All done!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
          if (progress == 1.0) ...[
            const SizedBox(height: 8),
            const Text('Amazing! All habits done today — +50 bonus XP!',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildStreakWarning(HabitProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${provider.streaksAtRisk} streak${provider.streaksAtRisk > 1 ? 's' : ''} at risk! Complete them today.',
              style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final defaultHabits = [
      'Study BCS 1 hour',
      'Morning exercise',
      'Read 20 minutes',
      'Review class notes',
      'Sleep by 11 PM',
    ];

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _green.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.repeat_rounded, size: 56, color: _green),
            ),
            const SizedBox(height: 16),
            const Text('No habits yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _fg)),
            const SizedBox(height: 8),
            const Text('Build consistency with daily habits', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            const Text('Quick add:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _fg)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: defaultHabits.map((h) => ActionChip(
                label: Text(h, style: const TextStyle(fontSize: 12)),
                backgroundColor: _green.withValues(alpha: 0.08),
                side: BorderSide(color: _green.withValues(alpha: 0.3)),
                onPressed: () => context.read<HabitProvider>().addHabit(h),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    final controller = TextEditingController();
    String frequency = 'daily';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ]),
              const SizedBox(height: 16),
              const Text('New Habit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Study BCS for 30 minutes',
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'daily', label: Text('Daily')),
                  ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ],
                selected: {frequency},
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) =>
                      states.contains(WidgetState.selected) ? _green.withValues(alpha: 0.15) : null),
                ),
                onSelectionChanged: (val) => setState(() => frequency = val.first),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    context.read<HabitProvider>().addHabit(name, frequency: frequency);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Habit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final Future<void> Function(BuildContext, String) onComplete;

  static const _green = Color(0xFF059669);
  static const _fg = Color(0xFF0F172A);

  const _HabitCard({required this.habit, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final done = habit.isCompletedToday;
    final atRisk = habit.isStreakAtRisk;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: done ? _green.withValues(alpha: 0.3) : Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => done ? null : onComplete(context, habit.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? _green : Colors.transparent,
                border: Border.all(color: done ? _green : Colors.grey[300]!, width: 2),
              ),
              child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: done ? Colors.grey : _fg,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: habit.streak > 0 ? (atRisk ? Colors.orange : Colors.deepOrange) : Colors.grey[300],
                    ),
                    const SizedBox(width: 3),
                    Text(
                      habit.streak == 0 ? 'Start your streak!' : '${habit.streak} day streak${atRisk ? ' — at risk!' : ''}',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500,
                        color: atRisk ? Colors.orange : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
                      child: Text(habit.frequency, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey[400]),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: Text('Remove "${habit.name}"? Your streak will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<HabitProvider>().deleteHabit(habit.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
