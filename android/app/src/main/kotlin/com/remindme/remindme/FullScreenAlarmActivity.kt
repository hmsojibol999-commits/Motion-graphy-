package com.remindme.remindme

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.random.Random

class FullScreenAlarmActivity : Activity() {
    private var payload: AlarmPayload? = null
    private var notifId: Int = 0
    private var mathAnswer = 0
    private var mathPrompt: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        val json = intent.getStringExtra("payload")
        payload = json?.let { AlarmPayloadJson.fromJson(it) }
        notifId = intent.getIntExtra("notificationId", 0)

        if (payload == null) { finish(); return }
        buildUI()
    }

    private fun buildUI() {
        val p = payload!!
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#0B0B0F"))
            gravity = Gravity.CENTER
            setPadding(60, 60, 60, 60)
        }

        root.addView(TextView(this).apply {
            text = "⏰"
            textSize = 72f
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#818CF8"))
        })

        root.addView(TextView(this).apply {
            text = p.title
            textSize = 28f
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            setPadding(0, 24, 0, 8)
        })

        if (p.note.isNotEmpty()) {
            root.addView(TextView(this).apply {
                text = p.note
                textSize = 16f
                gravity = Gravity.CENTER
                setTextColor(Color.parseColor("#9CA3AF"))
                setPadding(0, 0, 0, 32)
            })
        }

        val challengeBox = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 16)
        }
        root.addView(challengeBox)

        val doneBtn = Button(this).apply {
            text = "DONE"
            textSize = 18f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#4F46E5"))
            minimumHeight = 140
        }
        val snoozeBtn = Button(this).apply {
            text = if (p.currentSnoozeCount >= p.maxSnoozeCount) "SNOOZE LIMIT" else "SNOOZE ${p.snoozeMinutes}m"
            isEnabled = p.currentSnoozeCount < p.maxSnoozeCount
            textSize = 16f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#1E2028"))
            minimumHeight = 120
        }
        val skipBtn = Button(this).apply {
            text = "Skip"
            textSize = 14f
            setTextColor(Color.parseColor("#9CA3AF"))
            setBackgroundColor(Color.TRANSPARENT)
            minimumHeight = 96
        }

        when (p.dismissChallenge) {
            1 -> {
                // Math challenge
                val a = Random.nextInt(3, 12)
                val b = Random.nextInt(2, 10)
                mathAnswer = a + b
                mathPrompt = "$a + $b = ?"
                challengeBox.addView(TextView(this).apply {
                    text = "Solve to dismiss: $mathPrompt"
                    textSize = 18f
                    setTextColor(Color.WHITE)
                    gravity = Gravity.CENTER
                })
                val input = EditText(this).apply {
                    hint = "Answer"
                    setTextColor(Color.WHITE)
                    setHintTextColor(Color.parseColor("#6B7280"))
                    inputType = android.text.InputType.TYPE_CLASS_NUMBER
                    gravity = Gravity.CENTER
                }
                challengeBox.addView(input)
                doneBtn.setOnClickListener {
                    val v = input.text.toString().toIntOrNull()
                    if (v == mathAnswer) {
                        doDone()
                    } else {
                        input.error = "Wrong"
                    }
                }
            }
            2 -> {
                // Shake challenge - simplified: tap Done 3 times to emulate
                challengeBox.addView(TextView(this).apply {
                    text = "Tap DONE 3 times to confirm"
                    textSize = 14f
                    setTextColor(Color.parseColor("#9CA3AF"))
                    gravity = Gravity.CENTER
                })
                var taps = 0
                doneBtn.setOnClickListener {
                    taps++
                    doneBtn.text = "DONE (${taps}/3)"
                    if (taps >= 3) doDone()
                }
            }
            else -> doneBtn.setOnClickListener { doDone() }
        }

        snoozeBtn.setOnClickListener { doSnooze() }
        skipBtn.setOnClickListener { doSkip() }

        root.addView(doneBtn, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
            bottomMargin = 16
        })
        root.addView(snoozeBtn, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
            bottomMargin = 8
        })
        root.addView(skipBtn, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        setContentView(root)
    }

    private fun doDone() {
        val p = payload ?: return
        stopService(Intent(this, AlarmForegroundService::class.java))
        (getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager).cancel(notifId)
        val base = notifId - (notifId % 8)
        AlarmScheduler(this).cancel(listOf(base, base + 1, base + 2, base + 3, base + 4))
        PendingActionsStore(this).add(mapOf(
            "type" to "done", "id" to p.id, "at" to System.currentTimeMillis()))
        finish()
    }

    private fun doSnooze() {
        val p = payload ?: return
        if (p.currentSnoozeCount >= p.maxSnoozeCount) return
        val at = System.currentTimeMillis() + p.snoozeMinutes * 60_000L
        val snoozePayload = p.copy(
            nextFireAtMs = at,
            currentSnoozeCount = p.currentSnoozeCount + 1,
            isSnooze = true,
        )
        val base = notifId - (notifId % 8)
        AlarmScheduler(this).schedule(snoozePayload, listOf(base + 2))
        stopService(Intent(this, AlarmForegroundService::class.java))
        (getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager).cancel(notifId)
        PendingActionsStore(this).add(mapOf(
            "type" to "snooze", "id" to p.id, "untilMs" to at))
        finish()
    }

    private fun doSkip() {
        val p = payload ?: return
        stopService(Intent(this, AlarmForegroundService::class.java))
        (getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager).cancel(notifId)
        PendingActionsStore(this).add(mapOf(
            "type" to "skip",
            "id" to p.id,
            "isSnooze" to p.isSnooze,
            "at" to System.currentTimeMillis(),
        ))
        finish()
    }

    override fun onBackPressed() {
        // Prevent easy dismissal - require an action
    }
}
