package com.dct.tracking.android_tyd

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // No splash screen handling needed here anymore
        // SplashActivity handles the splash screen
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // MethodChannel to handle Android-specific actions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.dct.tracking/android_actions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openDownloads" -> {
                        try {
                            val intent = Intent("android.intent.action.VIEW_DOWNLOADS")
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INTENT_ERROR", e.message ?: "Failed to open downloads", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
