package com.remindme.remindme

import android.app.*
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.speech.tts.TextToSpeech
import androidx.core.app.NotificationCompat
import java.util.Locale

class AlarmForegroundService : Service(), TextToSpeech.OnInitListener {
    private var player: MediaPlayer? = null
    private var tts: TextToSpeech? = null
    private var vib: Vibrator? = null
    private var handler: Handler? = null
    private var flashlightRunnable: Runnable? = null
    private var cameraId: String? = null
    private var camManager: CameraManager? = null
    private var payload: AlarmPayload? = null
    private var fadeRunnable: Runnable? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val json = intent?.getStringExtra("payload") ?: return START_NOT_STICKY
        payload = AlarmPayloadJson.fromJson(json)
        val notifId = intent.getIntExtra("notificationId", 1)

        startForegroundInternal(notifId)
        startRinging(payload!!)
        return START_NOT_STICKY
    }

    private fun startForegroundInternal(notifId: Int) {
        AlarmScheduler(this).ensureChannels()
        val p = payload ?: return
        val pi = PendingIntent.getActivity(
            this, notifId,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val stopIntent = Intent(this, AlarmReceiver::class.java).apply {
            action = AlarmScheduler.ACTION_DONE
            putExtra("payload", AlarmPayloadJson.toJson(p))
            putExtra("notificationId", notifId)
        }
        val stopPi = PendingIntent.getBroadcast(
            this, notifId * 16 + 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val n = NotificationCompat.Builder(this, AlarmScheduler.CH_ALARM)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle(p.title)
            .setContentText(p.note.ifEmpty { "Reminder" })
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(pi)
            .setOngoing(true)
            .addAction(0, "STOP", stopPi) 
            .build()
            
        if (Build.VERSION.SDK_INT >= 34) {
            startForeground(notifId, n, android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(notifId, n)
        }
    }

    private fun startRinging(p: AlarmPayload) {
        try {
            player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                val uri: Uri = if (!p.soundPath.isNullOrEmpty() && java.io.File(p.soundPath).exists()) {
                    Uri.fromFile(java.io.File(p.soundPath!!))
                } else {
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                        ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                }
                setDataSource(this@AlarmForegroundService, uri)
                isLooping = p.ringRepeatCount > 1
                val initialVol = if (p.gradualVolume) 0.05f else (p.volumeLevel / 100f).coerceIn(0f, 1f)
                setVolume(initialVol, initialVol)
                prepare()
                start()
            }
            if (p.gradualVolume) startGradualFade(p)
        } catch (_: Exception) {}

        try {
            vib = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            val pattern = when (p.vibrationType) {
                0 -> longArrayOf(0, 500, 500, 500)
                1 -> longArrayOf(0, 1500, 800, 1500)
                2 -> if (p.vibrationPattern.isNotEmpty()) p.vibrationPattern.map { it.toLong() }.toLongArray() else longArrayOf(0, 500, 500)
                else -> longArrayOf(0, 500, 500)
            }
            if (Build.VERSION.SDK_INT >= 26) {
                vib?.vibrate(VibrationEffect.createWaveform(pattern, 0))
            } else {
                @Suppress("DEPRECATION") vib?.vibrate(pattern, 0)
            }
        } catch (_: Exception) {}

        if (p.flashlightBlink) startFlashlight()
        if (p.ttsRead) tts = TextToSpeech(this, this)

        handler = Handler(Looper.getMainLooper())
        val total = (p.ringDurationSec * p.ringRepeatCount * 1000L).coerceAtMost(5 * 60 * 1000L)
        handler?.postDelayed({ stopSelfSafely() }, total)
    }

    private fun startGradualFade(p: AlarmPayload) {
        fadeRunnable = object : Runnable {
            var step = 0
            override fun run() {
                step++
                val target = (p.volumeLevel / 100f).coerceIn(0f, 1f)
                val v = (step / 20f).coerceAtMost(target)
                try { player?.setVolume(v, v) } catch (_: Exception) {}
                if (v < target) handler?.postDelayed(this, 1000)
            }
        }
        handler = handler ?: Handler(Looper.getMainLooper())
        handler?.postDelayed(fadeRunnable!!, 1000)
    }

    private fun startFlashlight() {
        try {
            camManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            cameraId = camManager?.cameraIdList?.firstOrNull { id ->
                camManager?.getCameraCharacteristics(id)
                    ?.get(android.hardware.camera2.CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
            flashlightRunnable = object : Runnable {
                var on = false
                override fun run() {
                    on = !on
                    try { camManager?.setTorchMode(cameraId ?: return, on) } catch (_: Exception) {}
                    handler?.postDelayed(this, 400)
                }
            }
            handler = handler ?: Handler(Looper.getMainLooper())
            handler?.post(flashlightRunnable!!)
        } catch (_: Exception) {}
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale.getDefault()
            val p = payload ?: return
            val text = "${p.title}. ${p.note}".trim()
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, "rm_${p.id}")
        }
    }

    private fun stopSelfSafely() {
        try { stopSelf() } catch (_: Exception) {}
    }

    override fun onDestroy() {
        try { handler?.removeCallbacksAndMessages(null) } catch (_: Exception) {}
        try { player?.stop(); player?.release() } catch (_: Exception) {}
        player = null
        try { tts?.stop(); tts?.shutdown() } catch (_: Exception) {}
        tts = null
        try { vib?.cancel() } catch (_: Exception) {}
        try {
            flashlightRunnable?.let { handler?.removeCallbacks(it) }
            camManager?.setTorchMode(cameraId ?: "", false)
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
