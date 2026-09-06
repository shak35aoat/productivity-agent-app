import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/bcs_provider.dart';
import '../providers/xp_provider.dart';
import '../providers/focus_lock_provider.dart';
import '../services/focus_monitor_service.dart';
import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'pomodoro_screen.dart';
import 'bcs_screen.dart';
import 'chat_screen.dart';
import 'focus_lock_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _blue = Color(0xFF2563EB);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        onNavigate: (index) => setState(() => _currentIndex = index),
      ),
      const TasksScreen(),
      const PomodoroScreen(),
      const BcsScreen(),
      const ChatScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lockProvider = context.read<FocusLockProvider>();
      await Future.wait([
        context.read<TaskProvider>().loadTasks(),
        context.read<HabitProvider>().loadHabits(),
        context.read<BcsProvider>().load(),
        context.read<XpProvider>().load(),
        lockProvider.load(),
      ]);
      FocusMonitorService.instance.startMonitoring(lockProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: _blue.withValues(alpha: 0.12),
        elevation: 8,
        height: 62,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.dashboard_rounded, color: _blue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.task_alt_rounded, color: _blue),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.timer_rounded, color: Color(0xFF7C3AED)),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.school_rounded, color: Color(0xFF059669)),
            label: 'BCS',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined, color: Color(0xFF64748B)),
            selectedIcon: Icon(Icons.chat_rounded, color: _blue),
            label: 'Chat',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.small(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FocusLockScreen()),
              ),
              backgroundColor: Colors.white,
              foregroundColor: _blue,
              elevation: 4,
              tooltip: 'Focus Lock',
              child: const Icon(Icons.lock_clock_rounded),
            )
          : null,
    );
  }
}
