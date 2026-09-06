import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/focus_lock_provider.dart';

class FocusMonitorService with WidgetsBindingObserver {
  static final FocusMonitorService instance = FocusMonitorService._();
  FocusMonitorService._();

  static const _channel = MethodChannel('com.productivity_agent/focus_lock');
  static const _overrideKey = 'focus_override_until';
  static const _overrideDuration = Duration(minutes: 5);

  Timer? _timer;
  GlobalKey<NavigatorState>? navigatorKey;
  FocusLockProvider? _provider;
  bool _dialogShowing = false;
  bool _serviceRunning = false;

  static const blockedPackages = <String, String>{
    'com.facebook.katana': 'Facebook',
    'com.facebook.lite': 'Facebook Lite',
    'com.google.android.youtube': 'YouTube',
    'com.instagram.android': 'Instagram',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.ss.android.ugc.trill': 'TikTok',
  };

  Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasUsagePermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openPermissionSettings() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (_) {}
  }

  Future<String?> getForegroundApp() async {
    try {
      return await _channel.invokeMethod<String>('getForegroundApp');
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isOverrideActive() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_overrideKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  Future<void> _setOverride() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(_overrideDuration).millisecondsSinceEpoch;
    await prefs.setInt(_overrideKey, until);
  }

  void startMonitoring(FocusLockProvider provider) {
    _provider = provider;
    WidgetsBinding.instance.addObserver(this);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
    _tick();
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _provider = null;
    WidgetsBinding.instance.removeObserver(this);
    _stopNativeBlocker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
    }
  }

  Future<void> _tick() async {
    if (_provider == null) return;

    final active = _provider!.anyActiveNow;
    final override = await _isOverrideActive();

    if (active && !override) {
      await _ensureNativeBlockerRunning();
      await _checkAndBlock();
    } else {
      await _stopNativeBlocker();
    }
  }

  Future<void> _ensureNativeBlockerRunning() async {
    if (_serviceRunning) return;
    try {
      final label = _provider!.activeLocks.isNotEmpty
          ? _provider!.activeLocks.first.label
          : 'Focus Lock';
      await _channel.invokeMethod('startBlocker', {
        'packages': blockedPackages.keys.toList(),
        'label': label,
      });
      _serviceRunning = true;
    } catch (_) {}
  }

  Future<void> _stopNativeBlocker() async {
    if (!_serviceRunning) return;
    try {
      await _channel.invokeMethod('stopBlocker');
    } catch (_) {}
    _serviceRunning = false;
  }

  Future<void> _checkAndBlock() async {
    if (_provider == null || !_provider!.anyActiveNow) return;
    if (_dialogShowing) return;
    if (await _isOverrideActive()) return;

    final foreground = await getForegroundApp();
    if (foreground == null) return;

    final appName = blockedPackages[foreground];
    if (appName != null) {
      _showBlockingScreen(appName);
    }
  }

  void _showBlockingScreen(String appName) {
    final ctx = navigatorKey?.currentContext;
    if (ctx == null) return;
    if (_dialogShowing) return;

    _dialogShowing = true;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _FocusBlockDialog(
        appName: appName,
        onOverride: () async {
          await _setOverride();
          _dialogShowing = false;
        },
        onGoBack: () {
          _dialogShowing = false;
        },
      ),
    ).then((_) {
      _dialogShowing = false;
    });
  }
}

class _FocusBlockDialog extends StatelessWidget {
  final String appName;
  final VoidCallback onGoBack;
  final Future<void> Function() onOverride;

  const _FocusBlockDialog({
    required this.appName,
    required this.onGoBack,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1D4ED8),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '$appName is blocked',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Focus Lock schedule is active right now.\nStay focused — your future depends on it!',
                    style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BCS exam prep is more important than scrolling.',
                    style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        onGoBack();
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1D4ED8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Go Back to Study',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await onOverride();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Override (5 min break)',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
