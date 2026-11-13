package com.remindme.remindme

import android.content.Context
import com.google.gson.GsonBuilder
import com.google.gson.ToNumberPolicy
import com.google.gson.reflect.TypeToken

/** Stores actions (done/snooze/skip) fired from full-screen UI so Flutter
 *  can apply them to the DB next time the app opens. */
class PendingActionsStore(private val ctx: Context) {
    private val prefs = ctx.getSharedPreferences("rm_pending_actions", Context.MODE_PRIVATE)
    // Keep integral timestamps as Long so Flutter's standard channel codec can
    // serialize the queued maps without losing actions to unsupported numbers.
    private val gson = GsonBuilder()
        .setObjectToNumberStrategy(ToNumberPolicy.LONG_OR_DOUBLE)
        .create()

    fun add(action: Map<String, Any?>) {
        val list = readRaw().toMutableList()
        list.add(action)
        // Prevent an abandoned device from growing this preferences value forever.
        val bounded = if (list.size > 200) list.takeLast(200) else list
        prefs.edit().putString(KEY, gson.toJson(bounded)).apply()
        PendingActionNotifier.notifyPending()
    }

    fun consumeAll(): List<Map<String, Any?>> {
        val list = readRaw()
        prefs.edit().remove(KEY).apply()
        return list
    }

    private fun readRaw(): List<Map<String, Any?>> {
        val raw = prefs.getString(KEY, null) ?: return emptyList()
        return try {
            val t = object : TypeToken<List<Map<String, Any?>>>() {}.type
            gson.fromJson(raw, t) ?: emptyList()
        } catch (_: Exception) { emptyList() }
    }

    companion object { private const val KEY = "queue" }
}
