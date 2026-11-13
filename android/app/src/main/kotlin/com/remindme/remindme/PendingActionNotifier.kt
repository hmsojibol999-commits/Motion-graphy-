package com.remindme.remindme

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/** Delivers a small wake-up signal to an attached Flutter engine. The actual
 * action data remains persisted in SharedPreferences until Flutter consumes it. */
object PendingActionNotifier {
    @Volatile private var actionChannel: MethodChannel? = null

    fun attach(channel: MethodChannel) {
        actionChannel = channel
    }

    fun detach(channel: MethodChannel) {
        if (actionChannel === channel) actionChannel = null
    }

    fun notifyPending() {
        val channel = actionChannel ?: return
        Handler(Looper.getMainLooper()).post {
            if (actionChannel === channel) {
                channel.invokeMethod("pendingActionsChanged", null)
            }
        }
    }
}
