import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/focus_lock_provider.dart';
import '../services/focus_monitor_service.dart';

class FocusLockScreen extends StatefulWidget {
  const FocusLockScreen({super.key});

  @override
  State<FocusLockScreen> createState() => _FocusLockScreenState();
}

class _FocusLockScreenState extends State<FocusLockScreen> with WidgetsBindingObserver {
  bool _hasPermission = false;

  static const _blue = Color(0xFF2563EB);
  static const _bg = Color(0xFFF0F9FF);
  static const _fg = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final has = await FocusMonitorService.instance.hasPermission();
    if (mounted) setState(() => _hasPermission = has);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        title: const Text('Focus Lock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Consumer<FocusLockProvider>(
        builder: (_, provider, __) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_hasPermission && !kIsWeb) _buildPermissionCard(context),
                if (!_hasPermission && !kIsWeb) const SizedBox(height: 16),
                _buildInfoCard(context, provider),
                const SizedBox(height: 16),
                _buildBlockedApps(),
                const SizedBox(height: 16),
                _buildScheduleList(context, provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: _blue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text('Permission Required', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF92400E))),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'To detect and block apps, grant "Usage Access" permission. Tap the button below, find "Productivity Agent" and enable it.',
            style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await FocusMonitorService.instance.openPermissionSettings();
              },
              icon: const Icon(Icons.settings_rounded, size: 16),
              label: const Text('Grant Usage Access'),
              style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, FocusLockProvider provider) {
    final active = provider.anyActiveNow;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active
              ? [const Color(0xFF059669), const Color(0xFF10B981)]
              : [_blue, const Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: Icon(active ? Icons.lock_rounded : Icons.lock_open_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'Focus Lock Active' : 'Focus Lock Standby',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  active
                      ? '${provider.activeLocks.map((l) => l.label).join(", ")} is blocked right now'
                      : 'Set a schedule to block distracting apps',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedApps() {
    final apps = [
      ('Facebook', Icons.facebook_rounded, const Color(0xFF1877F2)),
      ('YouTube', Icons.play_circle_rounded, const Color(0xFFFF0000)),
      ('Instagram', Icons.camera_alt_rounded, const Color(0xFFE1306C)),
      ('TikTok', Icons.music_note_rounded, Colors.black87),
    ];

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
          const Text('Blocked Apps', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _fg)),
          const SizedBox(height: 4),
          const Text(
            'When Focus Lock is active, opening these apps shows a reminder to stay focused.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: apps.map((a) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: a.$3.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: a.$3.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(a.$2, color: a.$3, size: 16),
                  const SizedBox(width: 6),
                  Text(a.$1, style: TextStyle(color: a.$3, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.amber, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'When a schedule is active, a background monitor detects if you open a blocked app and shows a full-screen reminder to get back to studying.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(BuildContext context, FocusLockProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedules', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _fg)),
        const SizedBox(height: 10),
        if (provider.locks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              children: [
                Icon(Icons.schedule_rounded, size: 48, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text('No schedules yet', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                Text('Tap + to add a focus schedule', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          )
        else
          ...provider.locks.map((lock) => _LockCard(lock: lock, provider: provider)),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    final labelCtrl = TextEditingController(text: 'Study Session');
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 11, minute: 0);
    final selectedDays = <String>{'Mon', 'Tue', 'Wed', 'Thu', 'Fri'};
    final allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Focus Schedule', style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 14),
                const Text('Time Range', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: startTime);
                          if (t != null) setState(() => startTime = t);
                        },
                        child: Text(startTime.format(ctx)),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('to')),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final t = await showTimePicker(context: ctx, initialTime: endTime);
                          if (t != null) setState(() => endTime = t);
                        },
                        child: Text(endTime.format(ctx)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Repeat Days', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: allDays.map((d) {
                    final selected = selectedDays.contains(d);
                    return FilterChip(
                      label: Text(d),
                      selected: selected,
                      selectedColor: _blue.withValues(alpha: 0.15),
                      checkmarkColor: _blue,
                      onSelected: (val) => setState(() {
                        if (val) {
                          selectedDays.add(d);
                        } else {
                          selectedDays.remove(d);
                        }
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _blue),
              onPressed: () {
                if (labelCtrl.text.trim().isEmpty || selectedDays.isEmpty) return;
                final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
                final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
                context.read<FocusLockProvider>().addLock(FocusLock(
                  id: const Uuid().v4(),
                  label: labelCtrl.text.trim(),
                  startTime: startStr,
                  endTime: endStr,
                  days: selectedDays.toList(),
                ));
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

class _LockCard extends StatelessWidget {
  final FocusLock lock;
  final FocusLockProvider provider;

  const _LockCard({required this.lock, required this.provider});

  static const _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final active = lock.isActiveNow();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? _blue.withValues(alpha: 0.4) : Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (active ? _blue : Colors.grey).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(lock.enabled ? Icons.lock_rounded : Icons.lock_open_rounded,
                color: active ? _blue : Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(lock.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                    if (active) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(6)),
                        child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('${lock.timeRange}  •  ${lock.daysDisplay}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Switch(
            value: lock.enabled,
            activeThumbColor: _blue,
            onChanged: (_) => provider.toggleLock(lock.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
            onPressed: () => provider.deleteLock(lock.id),
          ),
        ],
      ),
    );
  }
}
