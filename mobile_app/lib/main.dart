import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'providers/task_provider.dart';
import 'providers/agent_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/bcs_provider.dart';
import 'providers/xp_provider.dart';
import 'providers/focus_lock_provider.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';
import 'services/focus_monitor_service.dart';
import 'screens/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  tz.initializeTimeZones();

  await DatabaseService.instance.init();

  NotificationService.instance.init();

  FocusMonitorService.instance.navigatorKey = navigatorKey;
  runApp(const ProductivityAgentApp());
}

class ProductivityAgentApp extends StatelessWidget {
  const ProductivityAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => AgentProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => BcsProvider()),
        ChangeNotifierProvider(create: (_) => XpProvider()),
        ChangeNotifierProvider(create: (_) => FocusLockProvider()),
      ],
      child: MaterialApp(
        title: 'Productivity Agent',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF2563EB).withValues(alpha: 0.12),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB));
              }
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B));
            }),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF0F9FF),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
