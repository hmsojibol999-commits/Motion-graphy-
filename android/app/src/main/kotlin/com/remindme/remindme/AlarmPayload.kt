package com.remindme.remindme

import com.google.gson.Gson
import com.google.gson.annotations.SerializedName

data class AlarmPayload(
    val id: String,
    val title: String,
    val note: String,
    val dueAtMs: Long,
    val nextFireAtMs: Long? = null,
    val isSnooze: Boolean = false,
    val currentSnoozeCount: Int = 0,
    val advanceMinutes: Int = 0,
    val alertType: Int = 0, // 0=notif, 1=fullscreen alarm
    val soundPath: String? = null,
    val soundName: String? = null,
    val vibrationType: Int = 0,
    val vibrationPattern: List<Int> = emptyList(),
    val flashlightBlink: Boolean = false,
    val ttsRead: Boolean = false,
    val gradualVolume: Boolean = false,
    val volumeLevel: Int = 100,
    val ringDurationSec: Int = 30,
    val ringRepeatCount: Int = 3,
    val snoozeMinutes: Int = 10,
    val maxSnoozeCount: Int = 5,
    val dismissChallenge: Int = 0,
    val priority: Int = 0,
    val status: Int = 0,
    val repeatType: Int = 0,
    val repeatInterval: Int = 1,
    val repeatWeekdays: List<Int> = emptyList(),
    val repeatMonthDay: Int? = null,
    val repeatNth: Int? = null,
    val repeatNthWeekday: Int? = null,
    val repeatEndType: Int = 0,
    val repeatEndDateMs: Long? = null,
    val repeatEndCount: Int? = null,
    val firedCount: Int = 0,
    val activeStartMin: Int? = null,
    val activeEndMin: Int? = null,
) {
    companion object {
        private val gson = Gson()
        fun fromMap(map: Map<String, Any?>): AlarmPayload =
            gson.fromJson(gson.toJson(map), AlarmPayload::class.java)
    }
}
