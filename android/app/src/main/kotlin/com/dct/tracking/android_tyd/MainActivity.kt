package com.dct.tracking.android_tyd

import android.content.Intent
import android.os.Bundle
import android.os.Build
import android.os.Environment
import android.content.ContentValues
import android.provider.MediaStore
import java.io.File
import java.io.FileOutputStream
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
                    "getSdkInt" -> {
                        result.success(Build.VERSION.SDK_INT)
                    }
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
                    "saveToDownloads" -> {
                        try {
                            val name = call.argument<String>("name") ?: "file.pdf"
                            val bytes = call.argument<ByteArray>("bytes")
                            val mime = call.argument<String>("mime") ?: "application/pdf"
                            if (bytes == null) {
                                result.error("ARG_ERROR", "bytes is null", null)
                                return@setMethodCallHandler
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                val resolver = applicationContext.contentResolver
                                val cv = ContentValues().apply {
                                    put(MediaStore.MediaColumns.DISPLAY_NAME, name)
                                    put(MediaStore.MediaColumns.MIME_TYPE, mime)
                                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                                }
                                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, cv)
                                if (uri == null) {
                                    result.error("SAVE_ERROR", "Failed to create MediaStore entry", null)
                                    return@setMethodCallHandler
                                }
                                resolver.openOutputStream(uri)?.use { os ->
                                    os.write(bytes)
                                }
                                val update = ContentValues().apply {
                                    put(MediaStore.MediaColumns.IS_PENDING, 0)
                                }
                                resolver.update(uri, update, null, null)
                                result.success(mapOf("uri" to uri.toString()))
                            } else {
                                val dir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
                                if (!dir.exists()) {
                                    dir.mkdirs()
                                }
                                val file = File(dir, name)
                                FileOutputStream(file).use { fos ->
                                    fos.write(bytes)
                                }
                                result.success(mapOf("path" to file.absolutePath))
                            }
                        } catch (e: SecurityException) {
                            result.error("PERMISSION_REQUIRED", e.message ?: "Permission required", null)
                        } catch (e: Exception) {
                            result.error("SAVE_ERROR", e.message ?: "Failed to save file", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
