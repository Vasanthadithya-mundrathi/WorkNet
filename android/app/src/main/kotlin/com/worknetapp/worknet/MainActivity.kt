package com.worknetapp.worknet

import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "worknet.discovery/service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val peerCount = call.argument<Int>("peerCount") ?: 0
                        val intent = WorkNetDiscoveryService.buildStartIntent(this, peerCount)
                        ContextCompat.startForegroundService(this, intent)
                        result.success(null)
                    }
                    "stop" -> {
                        startService(WorkNetDiscoveryService.buildStopIntent(this))
                        result.success(null)
                    }
                    "updateNotification" -> {
                        val peerCount = call.argument<Int>("peerCount") ?: 0
                        val intent = WorkNetDiscoveryService.buildStartIntent(this, peerCount)
                        startService(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
