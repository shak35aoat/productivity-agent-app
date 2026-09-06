package com.example.productivity_agent

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.productivity_agent/focus_lock"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getForegroundApp" -> result.success(getForegroundApp())
                    "hasUsagePermission" -> result.success(hasUsagePermission())
                    "openUsageSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "startBlocker" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        val label = call.argument<String>("label") ?: "Focus Lock"
                        val intent = Intent(this, FocusBlockerService::class.java).apply {
                            putStringArrayListExtra(FocusBlockerService.EXTRA_BLOCKED_PACKAGES, ArrayList(packages))
                            putExtra(FocusBlockerService.EXTRA_LABEL, label)
                        }
                        startForegroundService(intent)
                        result.success(true)
                    }
                    "stopBlocker" -> {
                        stopService(Intent(this, FocusBlockerService::class.java))
                        result.success(true)
                    }
                    "isBlockerRunning" -> result.success(FocusBlockerService.isRunning)
                    else -> result.notImplemented()
                }
            }
    }

    private fun getForegroundApp(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 10_000, now)
        return stats?.maxByOrNull { it.lastTimeUsed }?.packageName
    }

    private fun hasUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = appOps.unsafeCheckOpNoThrow(
            android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == android.app.AppOpsManager.MODE_ALLOWED
    }
}
