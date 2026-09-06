import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bcs_provider.dart';
import '../models/bcs_model.dart';

const _primary = Color(0xFFD97706);
const _accent = Color(0xFF059669);
const _bg = Color(0xFFFFFBEB);
const _fg = Color(0xFF0F172A);

class BcsScreen extends StatefulWidget {
  const BcsScreen({super.key});

  @override
  State<BcsScreen> createState() => _BcsScreenState();
}

class _BcsScreenState extends State<BcsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DateTime _examDate = DateTime(2027, 6, 1);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BcsProvider>().load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        title: const Text('BCS Preparation',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Syllabus'),
            Tab(text: 'Mock Tests'),
            Tab(text: 'Overview'),
          ],
        ),
      ),
      body: Consumer<BcsProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator(color: _primary));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _SyllabusTab(provider: provider),
              _MockTestTab(provider: provider),
              _OverviewTab(provider: provider, examDate: _examDate),
            ],
          );
        },
      ),
    );
  }
}

// ─── Syllabus Tab ─────────────────────────────────────────────────────────────

class _SyllabusTab extends StatelessWidget {
  final BcsProvider provider;
  const _SyllabusTab({required this.provider});

  static const _categories = [
    ('bangla', 'Bangla', Icons.translate_rounded, Color(0xFF4F46E5)),
    ('english', 'English', Icons.language_rounded, Color(0xFF0EA5E9)),
    ('math', 'Math & Mental', Icons.calculate_rounded, Color(0xFFF59E0B)),
    ('gk', 'General Knowledge', Icons.public_rounded, Color(0xFF059669)),
    ('eee', 'EEE Technical', Icons.electric_bolt_rounded, Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _categories.map((cat) {
        final subjects = provider.subjectsByCategory(cat.$1);
        final progress = provider.categoryProgress(cat.$1);
        return _CategorySection(
          categoryKey: cat.$1,
          label: cat.$2,
          icon: cat.$3,
          color: cat.$4,
          progress: progress,
          subjects: subjects,
          provider: provider,
        );
      }).toList(),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String categoryKey;
  final String label;
  final IconData icon;
  final Color color;
  final double progress;
  final List<BcsSubject> subjects;
  final BcsProvider provider;

  const _CategorySection({
    required this.categoryKey, required this.label, required this.icon,
    required this.color, required this.progress, required this.subjects,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _fg)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${(progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          children: subjects.map((s) => _SubjectRow(subject: s, color: color, provider: provider)).toList(),
          ),
        ),
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  final BcsSubject subject;
  final Color color;
  final BcsProvider provider;

  const _SubjectRow({required this.subject, required this.color, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _fg)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: subject.progressPercent,
                          minHeight: 5,
                          backgroundColor: Colors.grey[100],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${subject.completedTopics}/${subject.totalTopics}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[400]),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'progress', child: Text('Update Progress')),
              const PopupMenuItem(value: 'rename', child: Text('Rename Subject')),
            ],
            onSelected: (val) {
              if (val == 'progress') _showProgressDialog(context);
              if (val == 'rename') _showRenameDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showProgressDialog(BuildContext context) {
    int current = subject.completedTopics;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Topics completed: $current / ${subject.totalTopics}',
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 16),
              Slider(
                value: current.toDouble(),
                min: 0,
                max: subject.totalTopics.toDouble(),
                divisions: subject.totalTopics,
                activeColor: _primary,
                label: '$current',
                onChanged: (v) => setState(() => current = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _primary),
              onPressed: () {
                provider.updateProgress(subject.id, current);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: subject.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Subject', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Subject name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _primary),
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) provider.renameSubject(subject.id, name);
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

// ─── Mock Test Tab ─────────────────────────────────────────────────────────────

class _MockTestTab extends StatelessWidget {
  final BcsProvider provider;
  const _MockTestTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => _showAddTestDialog(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Log Mock Test Result',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
        if (provider.mockTests.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.quiz_outlined, size: 60, color: Color(0xFFD97706)),
                  SizedBox(height: 12),
                  Text('No mock tests logged yet',
                      style: TextStyle(fontWeight: FontWeight.w600, color: _fg)),
                  SizedBox(height: 6),
                  Text('Practice daily and track your scores!',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: provider.mockTests.length,
              itemBuilder: (context, index) =>
                  _MockTestCard(test: provider.mockTests[index], provider: provider),
            ),
          ),
      ],
    );
  }

  void _showAddTestDialog(BuildContext context) {
    final testNameCtrl = TextEditingController();
    final scoreCtrl = TextEditingController();
    final totalCtrl = TextEditingController(text: '100');
    String subject = 'Bangla';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Log Mock Test', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: testNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Test Name', hintText: 'BCS Model Test #5', border: OutlineInputBorder()),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: subject,
                  decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                  items: ['Bangla', 'English', 'Math', 'General Knowledge', 'EEE Technical', 'Full Mock']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => subject = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: scoreCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Score', border: OutlineInputBorder()),
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('/', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300))),
                    Expanded(
                      child: TextField(
                        controller: totalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _primary),
              onPressed: () {
                final score = int.tryParse(scoreCtrl.text);
                final total = int.tryParse(totalCtrl.text);
                if (testNameCtrl.text.trim().isEmpty || score == null || total == null || total == 0) return;
                context.read<BcsProvider>().addMockTest(
                    subject: subject, testName: testNameCtrl.text.trim(), score: score, totalMarks: total);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockTestCard extends StatelessWidget {
  final MockTestResult test;
  final BcsProvider provider;

  const _MockTestCard({required this.test, required this.provider});

  @override
  Widget build(BuildContext context) {
    final pct = test.percentage;
    final color = pct >= 70 ? _accent : pct >= 50 ? _primary : const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Text('${pct.toInt()}%',
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.testName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _fg),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${test.subject}  •  ${test.score}/${test.totalMarks}  •  ${DateFormat('MMM dd').format(test.date)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
            onPressed: () => provider.deleteMockTest(test.id),
          ),
        ],
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final BcsProvider provider;
  final DateTime examDate;

  const _OverviewTab({required this.provider, required this.examDate});

  @override
  Widget build(BuildContext context) {
    final daysLeft = examDate.difference(DateTime.now()).inDays;
    final overall = provider.overallProgress;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCountdownCard(daysLeft),
        const SizedBox(height: 14),
        _buildOverallCard(overall),
        const SizedBox(height: 14),
        _buildCategoryBars(),
        const SizedBox(height: 14),
        if (provider.mockTests.isNotEmpty) _buildMockTestSummary(),
      ],
    );
  }

  Widget _buildCountdownCard(int daysLeft) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.event_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$daysLeft days to go',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const Text('Until estimated BCS exam',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(DateFormat('MMMM dd, yyyy').format(examDate),
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallCard(double overall) {
    final pct = (overall * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Syllabus', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _fg)),
              Text('$pct%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: _primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: overall,
              minHeight: 10,
              backgroundColor: Colors.grey[100],
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            overall < 0.3 ? 'Just getting started — build the habit first!'
                : overall < 0.6 ? 'Good progress — keep the momentum!'
                : overall < 0.9 ? 'Excellent! Focus on weak subjects now.'
                : 'Outstanding! Time for full mock tests.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBars() {
    final cats = [
      ('bangla', 'Bangla', const Color(0xFF4F46E5)),
      ('english', 'English', const Color(0xFF0EA5E9)),
      ('math', 'Math', const Color(0xFFF59E0B)),
      ('gk', 'Gen. Knowledge', const Color(0xFF059669)),
      ('eee', 'EEE Technical', const Color(0xFF7C3AED)),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subject Progress', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _fg)),
          const SizedBox(height: 14),
          ...cats.map((c) {
            final pct = provider.categoryProgress(c.$1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(width: 100, child: Text(c.$2, style: const TextStyle(fontSize: 13, color: _fg))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation<Color>(c.$3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 34,
                    child: Text('${(pct * 100).toInt()}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 11, color: c.$3, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMockTestSummary() {
    final avg = provider.mockTests.map((t) => t.percentage).reduce((a, b) => a + b) / provider.mockTests.length;
    final best = provider.mockTests.reduce((a, b) => a.percentage > b.percentage ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mock Test Summary', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _fg)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Tests', '${provider.mockTests.length}', Icons.quiz_rounded),
              _statItem('Avg', '${avg.toStringAsFixed(0)}%', Icons.bar_chart_rounded),
              _statItem('Best', '${best.percentage.toInt()}%', Icons.emoji_events_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _primary, size: 22),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _fg)),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}
