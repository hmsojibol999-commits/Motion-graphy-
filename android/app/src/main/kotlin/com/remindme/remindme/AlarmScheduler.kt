package com.remindme.remindme

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import java.util.Calendar

/** Native exact-alarm scheduler. Pending schedules are mirrored to private
 * preferences so they can be restored after reboot, app update or time change. */
class AlarmScheduler(private val ctx: Context) {
    private val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val prefs = ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun ensureChannels() {
        if (Build.VERSION.SDK_INT >= 26) {
            val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(NotificationChannel(
                CH_NORMAL, "Reminder notifications", NotificationManager.IMPORTANCE_DEFAULT))
            nm.createNotificationChannel(NotificationChannel(
                CH_ALARM, "Full-screen alarms", NotificationManager.IMPORTANCE_HIGH).apply {
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            })
            nm.createNotificationChannel(NotificationChannel(
                CH_SNOOZE, "Snoozed reminders", NotificationManager.IMPORTANCE_DEFAULT))
        }
    }

    /** The first ID is the main alarm ID. Extra IDs are reserved for advance
     * alerts, snooze, and future alert variants. */
    fun schedule(p: AlarmPayload, ids: List<Int>) {
        val base = ids.firstOrNull() ?: return
        ensureChannels()
        val at = p.nextFireAtMs ?: p.dueAtMs
        if (at <= 0L) return
        val scheduled = p.copy(nextFireAtMs = at)
        saveSchedule(base, scheduled)
        arm(base, at, scheduled, isAdvance = false)
        if (!scheduled.isSnooze) scheduleAdvance(base, scheduled, at)
    }

    private fun scheduleAdvance(base: Int, p: AlarmPayload, fireAt: Long) {
        if (p.advanceMinutes <= 0) return
        val advAt = fireAt - p.advanceMinutes * 60_000L
        if (advAt > System.currentTimeMillis()) {
            arm(base + 1, advAt, p, isAdvance = true)
        }
    }

    private fun arm(id: Int, atMs: Long, p: AlarmPayload, isAdvance: Boolean) {
        val triggerAt = maxOf(atMs, System.currentTimeMillis() + 1_000L)
        val intent = Intent(ctx, AlarmReceiver::class.java).apply {
            action = ACTION_TRIGGER
            putExtra("payload", AlarmPayloadJson.toJson(p))
            putExtra("notificationId", id)
            putExtra("isAdvance", isAdvance)
        }
        val pi = PendingIntent.getBroadcast(
            ctx, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        try {
            if (Build.VERSION.SDK_INT >= 31 && !am.canScheduleExactAlarms()) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
            } else {
                val info = AlarmManager.AlarmClockInfo(triggerAt, showIntent(id))
                am.setAlarmClock(info, pi)
            }
        } catch (_: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pi)
        }
    }

    private fun showIntent(id: Int): PendingIntent {
        val intent = Intent(ctx, MainActivity::class.java)
            .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            ctx, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /** Cancel must recreate the original PendingIntent identity (including
     * ACTION_TRIGGER); extras are deliberately not part of its identity. */
    fun cancel(ids: List<Int>) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        for (id in ids) {
            val intent = Intent(ctx, AlarmReceiver::class.java).setAction(ACTION_TRIGGER)
            val pi = PendingIntent.getBroadcast(
                ctx, id, intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pi != null) am.cancel(pi)
            nm.cancel(id)
            prefs.edit().remove(scheduleKey(id)).apply()
        }
    }

    /** Remove every mirrored alarm before a full database-driven rebuild. */
    fun cancelAll() {
        val keys = prefs.all.keys.filter { it.startsWith(SCHEDULE_PREFIX) }
        for (key in keys) {
            val id = key.removePrefix(SCHEDULE_PREFIX).toIntOrNull() ?: continue
            val base = id - (id % 8)
            cancel(listOf(base, base + 1, base + 2, base + 3, base + 4))
        }
    }

    /** Called from BOOT_COMPLETED, TIME_SET, TIMEZONE_CHANGED and package
     * replacement. SharedPreferences survive ordinary app updates/reboots. */
    fun restoreCachedSchedules() {
        val entries = prefs.all.filterKeys { it.startsWith(SCHEDULE_PREFIX) }
        entries.forEach { (key, value) ->
            val base = key.removePrefix(SCHEDULE_PREFIX).toIntOrNull() ?: return@forEach
            val json = value as? String ?: return@forEach
            try {
                val payload = AlarmPayloadJson.fromJson(json)
                val fireAt = payload.nextFireAtMs ?: payload.dueAtMs
                if (fireAt <= 0L) {
                    prefs.edit().remove(key).apply()
                } else {
                    arm(base, fireAt, payload, isAdvance = false)
                    if (!payload.isSnooze) scheduleAdvance(base, payload, fireAt)
                }
            } catch (_: Exception) {
                prefs.edit().remove(key).apply()
            }
        }
    }

    private fun saveSchedule(base: Int, p: AlarmPayload) {
        prefs.edit().putString(scheduleKey(base), AlarmPayloadJson.toJson(p)).apply()
    }

    fun removeCachedSchedule(base: Int) {
        prefs.edit().remove(scheduleKey(base)).apply()
    }

    /** Re-arm a repeating reminder immediately after it fires. The original
     * dueAtMs remains the recurrence anchor; nextFireAtMs tracks this firing. */
    fun armNaiveNext(p: AlarmPayload, baseId: Int): AlarmPayload? {
        if (p.isSnooze || p.repeatType == 0) {
            removeCachedSchedule(baseId)
            return null
        }
        if (p.repeatEndType == 2 && p.repeatEndCount != null &&
            p.firedCount + 1 >= p.repeatEndCount) {
            removeCachedSchedule(baseId)
            return null
        }

        val currentAt = p.nextFireAtMs ?: p.dueAtMs
        var next = computeNaiveNext(p, currentAt) ?: run {
            removeCachedSchedule(baseId)
            return null
        }
        if (p.repeatEndType == 1 && p.repeatEndDateMs != null &&
            next > endOfDay(p.repeatEndDateMs)) {
            removeCachedSchedule(baseId)
            return null
        }

        // A device may have been powered off for several repeat intervals.
        // Fast-forward without creating a burst of stale alarms. Minute/hour
        // intervals use arithmetic so a long offline period cannot create a
        // large loop or a chain of immediate alarms.
        val now = System.currentTimeMillis()
        var fired = p.firedCount + 1
        if (next <= now && (p.repeatType == 1 || p.repeatType == 2)) {
            val unit = if (p.repeatType == 1) 60_000L else 3_600_000L
            val step = p.repeatInterval.coerceIn(1, 100_000).toLong() * unit
            val missed = ((now - next) / step) + 1L
            if (p.repeatEndType == 2 && p.repeatEndCount != null &&
                fired.toLong() + missed >= p.repeatEndCount.toLong()) {
                removeCachedSchedule(baseId)
                return null
            }
            fired = (fired.toLong() + missed).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
            next += missed * step
        }
        var safety = 0
        while (next <= now && safety++ < 5000) {
            if (p.repeatEndType == 2 && p.repeatEndCount != null && fired >= p.repeatEndCount) {
                removeCachedSchedule(baseId)
                return null
            }
            next = computeNaiveNext(p, next) ?: run {
                removeCachedSchedule(baseId)
                return null
            }
            fired++
            if (p.repeatEndType == 1 && p.repeatEndDateMs != null &&
                next > endOfDay(p.repeatEndDateMs)) {
                removeCachedSchedule(baseId)
                return null
            }
        }
        if (p.repeatEndType == 1 && p.repeatEndDateMs != null &&
            next > endOfDay(p.repeatEndDateMs)) {
            removeCachedSchedule(baseId)
            return null
        }
        val updated = p.copy(firedCount = fired, nextFireAtMs = next, currentSnoozeCount = 0)
        saveSchedule(baseId, updated)
        arm(baseId, next, updated, isAdvance = false)
        scheduleAdvance(baseId, updated, next)
        return updated
    }

    private fun computeNaiveNext(p: AlarmPayload, currentAtMs: Long): Long? {
        val current = Calendar.getInstance().apply { timeInMillis = currentAtMs }
        val anchor = Calendar.getInstance().apply { timeInMillis = p.dueAtMs }
        val hour = anchor.get(Calendar.HOUR_OF_DAY)
        val minute = anchor.get(Calendar.MINUTE)
        val second = anchor.get(Calendar.SECOND)
        val millis = anchor.get(Calendar.MILLISECOND)
        fun restoreWallClock() {
            current.set(Calendar.HOUR_OF_DAY, hour)
            current.set(Calendar.MINUTE, minute)
            current.set(Calendar.SECOND, second)
            current.set(Calendar.MILLISECOND, millis)
        }

        when (p.repeatType) {
            // Elapsed-time intervals are absolute durations, not wall-clock
            // calendar increments, so DST changes cannot stretch or shrink them.
            1 -> return currentAtMs + p.repeatInterval.coerceIn(1, 100_000).toLong() * 60_000L
            2 -> return currentAtMs + p.repeatInterval.coerceIn(1, 100_000).toLong() * 3_600_000L
            3 -> { current.add(Calendar.DAY_OF_YEAR, 1); restoreWallClock() }
            4 -> {
                val days = p.repeatWeekdays.map { dartToJavaWeekday(it) }.toSet()
                if (days.isEmpty()) {
                    current.add(Calendar.DAY_OF_YEAR, 7)
                } else {
                    var tries = 0
                    do {
                        current.add(Calendar.DAY_OF_YEAR, 1)
                        tries++
                    } while (tries <= 7 && current.get(Calendar.DAY_OF_WEEK) !in days)
                }
                restoreWallClock()
            }
            5 -> {
                current.set(Calendar.DAY_OF_MONTH, 1)
                current.add(Calendar.MONTH, 1)
                val day = (p.repeatMonthDay ?: anchor.get(Calendar.DAY_OF_MONTH))
                    .coerceIn(1, current.getActualMaximum(Calendar.DAY_OF_MONTH))
                current.set(Calendar.DAY_OF_MONTH, day)
                restoreWallClock()
            }
            6 -> {
                current.set(Calendar.DAY_OF_MONTH, 1)
                current.add(Calendar.MONTH, 1)
                current.set(Calendar.DAY_OF_MONTH, current.getActualMaximum(Calendar.DAY_OF_MONTH))
                restoreWallClock()
            }
            7 -> {
                val nth = p.repeatNth ?: 1
                val fallbackWeekday = when (anchor.get(Calendar.DAY_OF_WEEK)) {
                    Calendar.MONDAY -> 1
                    Calendar.TUESDAY -> 2
                    Calendar.WEDNESDAY -> 3
                    Calendar.THURSDAY -> 4
                    Calendar.FRIDAY -> 5
                    Calendar.SATURDAY -> 6
                    else -> 7
                }
                val weekday = dartToJavaWeekday(p.repeatNthWeekday ?: fallbackWeekday)
                current.set(Calendar.DAY_OF_MONTH, 1)
                current.add(Calendar.MONTH, 1)
                current.set(Calendar.DAY_OF_MONTH, 1)
                if (nth < 0) {
                    current.set(Calendar.DAY_OF_MONTH, current.getActualMaximum(Calendar.DAY_OF_MONTH))
                    while (current.get(Calendar.DAY_OF_WEEK) != weekday) current.add(Calendar.DAY_OF_MONTH, -1)
                } else {
                    // A fifth weekday is not present in every month. Skip those
                    // months instead of silently ending the recurring reminder.
                    var found = false
                    var monthsChecked = 0
                    while (!found && monthsChecked++ < 24) {
                        current.set(Calendar.DAY_OF_MONTH, 1)
                        while (current.get(Calendar.DAY_OF_WEEK) != weekday) {
                            current.add(Calendar.DAY_OF_MONTH, 1)
                        }
                        val targetDay = current.get(Calendar.DAY_OF_MONTH) +
                            (nth.coerceIn(1, 5) - 1) * 7
                        if (targetDay <= current.getActualMaximum(Calendar.DAY_OF_MONTH)) {
                            current.set(Calendar.DAY_OF_MONTH, targetDay)
                            found = true
                        } else {
                            current.set(Calendar.DAY_OF_MONTH, 1)
                            current.add(Calendar.MONTH, 1)
                        }
                    }
                    if (!found) return null
                }
                restoreWallClock()
            }
            8 -> {
                current.add(Calendar.YEAR, 1)
                current.set(Calendar.MONTH, anchor.get(Calendar.MONTH))
                current.set(Calendar.DAY_OF_MONTH, minOf(
                    anchor.get(Calendar.DAY_OF_MONTH), current.getActualMaximum(Calendar.DAY_OF_MONTH)))
                restoreWallClock()
            }
            else -> return null
        }
        return current.timeInMillis
    }

    private fun dartToJavaWeekday(day: Int): Int = when (day) {
        1 -> Calendar.MONDAY
        2 -> Calendar.TUESDAY
        3 -> Calendar.WEDNESDAY
        4 -> Calendar.THURSDAY
        5 -> Calendar.FRIDAY
        6 -> Calendar.SATURDAY
        else -> Calendar.SUNDAY
    }

    private fun endOfDay(timestamp: Long): Long = Calendar.getInstance().apply {
        timeInMillis = timestamp
        set(Calendar.HOUR_OF_DAY, 23)
        set(Calendar.MINUTE, 59)
        set(Calendar.SECOND, 59)
        set(Calendar.MILLISECOND, 999)
    }.timeInMillis

    fun canScheduleExactAlarms(): Boolean {
        if (Build.VERSION.SDK_INT < 31) return true
        return am.canScheduleExactAlarms()
    }

    fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < 34) return true
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return nm.canUseFullScreenIntent()
    }

    fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < 33) return true
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return nm.areNotificationsEnabled()
    }

    fun isIgnoringBatteryOptimizations(): Boolean {
        val pm = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isIgnoringBatteryOptimizations(ctx.packageName)
    }

    companion object {
        const val CH_NORMAL = "remindme_normal"
        const val CH_ALARM = "remindme_alarm"
        const val CH_SNOOZE = "remindme_snooze"
        const val ACTION_TRIGGER = "com.remindme.remindme.TRIGGER"
        const val ACTION_DONE = "com.remindme.remindme.DONE"
        const val ACTION_SNOOZE = "com.remindme.remindme.SNOOZE"
        const val ACTION_SKIP = "com.remindme.remindme.SKIP"
        private const val PREFS_NAME = "remindme_alarm_schedule_cache"
        private const val SCHEDULE_PREFIX = "schedule_"
        private fun scheduleKey(id: Int) = SCHEDULE_PREFIX + id
    }
}

object AlarmPayloadJson {
    private val gson = com.google.gson.Gson()
    fun toJson(p: AlarmPayload): String = gson.toJson(p)
    fun fromJson(s: String): AlarmPayload = gson.fromJson(s, AlarmPayload::class.java)
}
