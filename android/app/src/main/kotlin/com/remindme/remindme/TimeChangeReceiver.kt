package com.remindme.remindme

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class TimeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED) {
            AlarmScheduler(ctx).restoreCachedSchedules()
        }
    }
}
