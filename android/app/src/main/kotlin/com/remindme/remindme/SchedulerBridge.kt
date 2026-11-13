package com.remindme.remindme

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SchedulerBridge(private val ctx: Context) {
    private val scheduler = AlarmScheduler(ctx)

    val handler: MethodChannel.MethodCallHandler = MethodChannel.MethodCallHandler { call, result ->
        try {
            when (call.method) {
                "schedule" -> handleSchedule(call, result)
                "cancel" -> handleCancel(call, result)
                "cancelAll" -> { scheduler.cancelAll(); result.success(true) }
                "canScheduleExactAlarms" -> result.success(scheduler.canScheduleExactAlarms())
                "hasNotificationPermission" -> result.success(scheduler.hasNotificationPermission())
                "canUseFullScreenIntent" -> result.success(scheduler.canUseFullScreenIntent())
                "isIgnoringBatteryOptimizations" -> result.success(scheduler.isIgnoringBatteryOptimizations())
                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= 31) {
                        ctx.startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            .setData(Uri.parse("package:${ctx.packageName}")))
                    }
                    result.success(true)
                }
                "openNotificationSettings" -> {
                    ctx.startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, ctx.packageName))
                    result.success(true)
                }
                "openBatteryOptimizationSettings" -> {
                    try {
                        ctx.startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            .setData(Uri.parse("package:${ctx.packageName}")))
                    } catch (_: Exception) {
                        ctx.startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    }
                    result.success(true)
                }
                "openFullScreenIntentSettings" -> {
                    if (Build.VERSION.SDK_INT >= 34) {
                        try {
                            ctx.startActivity(Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                .setData(Uri.parse("package:${ctx.packageName}")))
                        } catch (_: Exception) {}
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("BRIDGE", e.message, null)
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleSchedule(call: MethodCall, result: MethodChannel.Result) {
        val reminderMap = call.argument<Map<String, Any?>>("reminder")
        val ids = call.argument<List<Int>>("notificationIds")
        if (reminderMap == null || ids == null) {
            result.error("BAD_ARG", "Missing args", null); return
        }
        val payload = AlarmPayload.fromMap(reminderMap)
        scheduler.schedule(payload, ids)
        result.success(true)
    }

    @Suppress("UNCHECKED_CAST")
    private fun handleCancel(call: MethodCall, result: MethodChannel.Result) {
        val ids = call.argument<List<Int>>("ids") ?: emptyList<Int>()
        scheduler.cancel(ids)
        result.success(true)
    }
}
