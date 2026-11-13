package com.remindme.remindme

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val payloadJson = intent.getStringExtra("payload")
        val notifId = intent.getIntExtra("notificationId", 0)
        val isAdvance = intent.getBooleanExtra("isAdvance", false)
        val action = intent.action

        val payload = payloadJson?.let { AlarmPayloadJson.fromJson(it) }
            ?: return

        when (action) {
            AlarmScheduler.ACTION_DONE -> handleDone(ctx, payload, notifId)
            AlarmScheduler.ACTION_SNOOZE -> handleSnooze(ctx, payload, notifId)
            AlarmScheduler.ACTION_SKIP -> handleSkip(ctx, payload, notifId)
            else -> fire(ctx, payload, notifId, isAdvance)
        }
    }

    private fun fire(ctx: Context, p: AlarmPayload, notifId: Int, isAdvance: Boolean) {
        // Snooze count belongs to one occurrence. Reset it when a fresh regular
        // repeat starts, but retain it while the same occurrence is snoozed.
        val ringing = if (!isAdvance && !p.isSnooze && p.repeatType != 0) {
            p.copy(currentSnoozeCount = 0)
        } else p
        val scheduler = AlarmScheduler(ctx)
        val nextPayload = if (!isAdvance) scheduler.armNaiveNext(ringing, notifId) else {
            scheduler.removeCachedSchedule(notifId)
            null
        }
        // Persist each actual occurrence so Flutter can reconcile the local
        // database with alarms that fired while the app process was closed.
        if (!isAdvance && !ringing.isSnooze) {
            val firedCount = nextPayload?.firedCount ?: (ringing.firedCount + 1)
            PendingActionsStore(ctx).add(mapOf(
                "type" to "fired",
                "id" to ringing.id,
                "firedCount" to firedCount,
                "nextFireAtMs" to nextPayload?.nextFireAtMs,
                "hasNext" to (nextPayload != null),
                "currentSnoozeCount" to 0,
                "at" to System.currentTimeMillis(),
            ))
        }

        if (ringing.alertType == 1 && !isAdvance) {
            // Full-screen alarm
            val fullIntent = Intent(ctx, FullScreenAlarmActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
                putExtra("payload", AlarmPayloadJson.toJson(ringing))
                putExtra("notificationId", notifId)
            }
            try { ctx.startActivity(fullIntent) } catch (_: Exception) {}
            // Also show heads-up notification as backup
            showNotification(ctx, ringing, notifId, isAdvance, highPriority = true)
            // Start foreground sound service
            val svc = Intent(ctx, AlarmForegroundService::class.java).apply {
                putExtra("payload", AlarmPayloadJson.toJson(ringing))
                putExtra("notificationId", notifId)
            }
            try {
                if (Build.VERSION.SDK_INT >= 26) ctx.startForegroundService(svc) else ctx.startService(svc)
            } catch (_: Exception) {}
        } else {
            showNotification(ctx, ringing, notifId, isAdvance, highPriority = ringing.alertType == 1)
            if (!isAdvance) {
                val svc = Intent(ctx, AlarmForegroundService::class.java).apply {
                    putExtra("payload", AlarmPayloadJson.toJson(ringing))
                    putExtra("notificationId", notifId)
                }
                try {
                    if (Build.VERSION.SDK_INT >= 26) ctx.startForegroundService(svc) else ctx.startService(svc)
                } catch (_: Exception) {}
            }
        }
    }

    private fun showNotification(ctx: Context, p: AlarmPayload, id: Int, advance: Boolean, highPriority: Boolean) {
        AlarmScheduler(ctx).ensureChannels()
        val title = if (advance) "Coming up: ${p.title}" else p.title
        val body = if (advance) "In ${p.advanceMinutes} minutes" else p.note

        val donePI = if (!advance) actionPending(ctx, p, id, AlarmScheduler.ACTION_DONE) else null
        val snoozePI = if (!advance) actionPending(ctx, p, id, AlarmScheduler.ACTION_SNOOZE) else null
        val skipPI = if (!advance) actionPending(ctx, p, id, AlarmScheduler.ACTION_SKIP) else null

        val contentPI = PendingIntent.getActivity(
            ctx, id,
            Intent(ctx, MainActivity::class.java)
                .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(
            ctx, if (highPriority) AlarmScheduler.CH_ALARM else AlarmScheduler.CH_NORMAL
        )
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(if (highPriority) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(false)
            .setOngoing(false)
            .setContentIntent(contentPI)
        if (!advance) {
            builder.addAction(0, "Done", donePI!!)
            if (p.currentSnoozeCount < p.maxSnoozeCount) {
                builder.addAction(0, "Snooze ${p.snoozeMinutes}m", snoozePI!!)
            }
            builder.addAction(0, "Skip", skipPI!!)
        }

        if (highPriority && !advance) {
            builder.setFullScreenIntent(
                PendingIntent.getActivity(
                    ctx, id,
                    Intent(ctx, FullScreenAlarmActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        putExtra("payload", AlarmPayloadJson.toJson(p))
                        putExtra("notificationId", id)
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                ),
                true
            )
        }

        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(id, builder.build())
    }

    private fun actionPending(ctx: Context, p: AlarmPayload, notifId: Int, action: String): PendingIntent {
        val intent = Intent(ctx, AlarmReceiver::class.java).apply {
            this.action = action
            putExtra("payload", AlarmPayloadJson.toJson(p))
            putExtra("notificationId", notifId)
        }
        return PendingIntent.getBroadcast(
            // The action is part of PendingIntent identity, so the same stable
            // request code is safe and avoids integer overflow for hashed IDs.
            ctx, notifId, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun handleDone(ctx: Context, p: AlarmPayload, notifId: Int) {
        dismiss(ctx, notifId)
        stopService(ctx)
        val base = notifId - (notifId % 8)
        AlarmScheduler(ctx).cancel(listOf(base, base + 1, base + 2, base + 3, base + 4))
        PendingActionsStore(ctx).add(mapOf("type" to "done", "id" to p.id, "at" to System.currentTimeMillis()))
    }

    private fun handleSnooze(ctx: Context, p: AlarmPayload, notifId: Int) {
        dismiss(ctx, notifId)
        stopService(ctx)
        if (p.currentSnoozeCount >= p.maxSnoozeCount) {
            handleSkip(ctx, p, notifId)
            return
        }
        val at = System.currentTimeMillis() + p.snoozeMinutes * 60_000L
        val snoozePayload = p.copy(
            nextFireAtMs = at,
            currentSnoozeCount = p.currentSnoozeCount + 1,
            isSnooze = true,
        )
        val base = baseNotifId(p, notifId)
        AlarmScheduler(ctx).schedule(snoozePayload, listOf(base + 2))
        PendingActionsStore(ctx).add(mapOf("type" to "snooze", "id" to p.id, "untilMs" to at))
    }

    private fun handleSkip(ctx: Context, p: AlarmPayload, notifId: Int) {
        dismiss(ctx, notifId)
        stopService(ctx)
        PendingActionsStore(ctx).add(mapOf(
            "type" to "skip",
            "id" to p.id,
            "isSnooze" to p.isSnooze,
            "at" to System.currentTimeMillis(),
        ))
    }

    private fun dismiss(ctx: Context, notifId: Int) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.cancel(notifId)
    }

    private fun stopService(ctx: Context) {
        try { ctx.stopService(Intent(ctx, AlarmForegroundService::class.java)) } catch (_: Exception) {}
    }

    private fun baseNotifId(p: AlarmPayload, currentId: Int): Int {
        // IDs use a fixed group of eight per reminder (main, advance, snooze).
        return currentId - (currentId % 8)
    }
}
