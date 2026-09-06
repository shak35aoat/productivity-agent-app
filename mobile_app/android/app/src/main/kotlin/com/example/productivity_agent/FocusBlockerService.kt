package com.example.productivity_agent

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

class FocusBlockerService : Service() {

    companion object {
        const val CHANNEL_ID = "focus_blocker_channel"
        const val NOTIFICATION_ID = 9001
        const val EXTRA_BLOCKED_PACKAGES = "blocked_packages"
        const val EXTRA_LABEL = "focus_label"

        var blockedPackages: Set<String> = emptySet()
        var focusLabel: String = "Focus Lock"
        var isRunning = false
    }

    private val handler = Handler(Looper.getMainLooper())
    private var lastBlockedPackage: String? = null
    private var lastBlockTime = 0L

    private val checkRunnable = object : Runnable {
        override fun run() {
            checkForegroundApp()
            handler.postDelayed(this, 3000)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.let {
            val packages = it.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)
            if (packages != null) blockedPackages = packages.toSet()
            focusLabel = it.getStringExtra(EXTRA_LABEL) ?: "Focus Lock"
        }

        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())

        if (!isRunning) {
            isRunning = true
            handler.post(checkRunnable)
        }

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        handler.removeCallbacks(checkRunnable)
    }

    private fun checkForegroundApp() {
        if (blockedPackages.isEmpty()) return

        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 10_000, now)
        val foreground = stats?.maxByOrNull { it.lastTimeUsed }?.packageName ?: return

        if (foreground == packageName) return
        if (foreground == lastBlockedPackage && now - lastBlockTime < 10_000) return

        if (blockedPackages.contains(foreground)) {
            lastBlockedPackage = foreground
            lastBlockTime = now
            launchBlockerActivity(foreground)
        }
    }

    private fun launchBlockerActivity(blockedPackage: String) {
        val intent = Intent(this, BlockedAppActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(BlockedAppActivity.EXTRA_PACKAGE, blockedPackage)
            putExtra(BlockedAppActivity.EXTRA_LABEL, focusLabel)
        }
        startActivity(intent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Lock Monitor",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitors and blocks distracting apps during focus time"
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("Focus Lock Active")
            .setContentText("Blocking distracting apps")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
}
