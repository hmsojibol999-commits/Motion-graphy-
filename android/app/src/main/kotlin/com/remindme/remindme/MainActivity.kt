package com.remindme.remindme

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var actionChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.remindme.remindme/scheduler")
            .setMethodCallHandler(SchedulerBridge(this).handler)

        actionChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.remindme.remindme/actions",
        ).also { channel ->
            PendingActionNotifier.attach(channel)
        }
        actionChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumePendingActions" -> {
                    result.success(PendingActionsStore(this).consumeAll())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        actionChannel?.let { PendingActionNotifier.detach(it) }
        actionChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
