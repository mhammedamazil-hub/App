package com.taskflow.taskflow

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "taskflow.app/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // App-private, persistent directory used for taskflow_data.json.
                    "getDocumentsDirectory" -> {
                        result.success(filesDir.absolutePath)
                    }
                    "copyToClipboard" -> {
                        val text = call.argument<String>("text") ?: ""
                        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        cm.setPrimaryClip(ClipData.newPlainText("taskflow", text))
                        result.success(null)
                    }
                    "getClipboard" -> {
                        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        val clip = cm.primaryClip
                        result.success(
                            if (clip != null && clip.itemCount > 0) {
                                clip.getItemAt(0).coerceToText(this).toString()
                            } else {
                                null
                            }
                        )
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
