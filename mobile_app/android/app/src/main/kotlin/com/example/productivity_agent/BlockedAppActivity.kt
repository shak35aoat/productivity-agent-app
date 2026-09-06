package com.example.productivity_agent

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.CountDownTimer
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class BlockedAppActivity : Activity() {

    companion object {
        const val EXTRA_PACKAGE = "blocked_package"
        const val EXTRA_LABEL = "focus_label"
    }

    private var countDownTimer: CountDownTimer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val blockedPackage = intent.getStringExtra(EXTRA_PACKAGE) ?: ""
        val focusLabel = intent.getStringExtra(EXTRA_LABEL) ?: "Focus Lock"
        val appName = getAppName(blockedPackage)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF1D4ED8.toInt())
            setPadding(64, 64, 64, 64)
        }

        val lockIcon = TextView(this).apply {
            text = "\uD83D\uDD12"
            textSize = 56f
            gravity = Gravity.CENTER
        }

        val title = TextView(this).apply {
            text = "$appName is blocked"
            textSize = 26f
            setTextColor(0xFFFFFFFF.toInt())
            setTypeface(null, android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, 48, 0, 24)
        }

        val subtitle = TextView(this).apply {
            text = "$focusLabel is active right now.\nStay focused — your future depends on it!"
            textSize = 16f
            setTextColor(0xB3FFFFFF.toInt())
            gravity = Gravity.CENTER
            setLineSpacing(8f, 1f)
        }

        val motivation = TextView(this).apply {
            text = "BCS exam prep is more important than scrolling."
            textSize = 14f
            setTextColor(0xFFFFC107.toInt())
            setTypeface(null, android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 0)
        }

        val spacer = View(this).apply {
            minimumHeight = 96
        }

        val goBackButton = Button(this).apply {
            text = "Go Back to Study"
            textSize = 16f
            setTextColor(0xFF1D4ED8.toInt())
            setBackgroundColor(0xFFFFFFFF.toInt())
            setPadding(32, 32, 32, 32)
            setOnClickListener {
                launchProductivityApp()
                finish()
            }
        }

        val overrideButton = Button(this).apply {
            text = "Override (5 min break)"
            textSize = 13f
            setTextColor(0x80FFFFFF.toInt())
            setBackgroundColor(0x00000000)
            setOnClickListener {
                stopService(Intent(this@BlockedAppActivity, FocusBlockerService::class.java))
                finish()
            }
        }

        root.addView(lockIcon)
        root.addView(title)
        root.addView(subtitle)
        root.addView(motivation)
        root.addView(spacer)
        root.addView(goBackButton)
        root.addView(overrideButton)

        setContentView(root)

        countDownTimer = object : CountDownTimer(30_000, 1000) {
            override fun onTick(millisUntilFinished: Long) {}
            override fun onFinish() {
                launchProductivityApp()
                finish()
            }
        }.start()
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
    }

    override fun onBackPressed() {
        launchProductivityApp()
        super.onBackPressed()
    }

    private fun getAppName(packageName: String): String {
        return try {
            val pm = packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            "This app"
        }
    }

    private fun launchProductivityApp() {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(intent)
    }
}
