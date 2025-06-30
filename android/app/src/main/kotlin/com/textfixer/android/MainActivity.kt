package com.textfixer.android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.graphics.Color

class MainActivity: FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.textfixer.android/intent"
    }
    
    private var selectedText: String? = null

    override fun getBackgroundMode(): BackgroundMode {
        return if (isTextProcessingIntent()) {
            BackgroundMode.transparent
        } else {
            BackgroundMode.opaque
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (isTextProcessingIntent()) {
            configureTransparentWindow()
        }
        
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getIntentText" -> result.success(selectedText)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun isTextProcessingIntent(): Boolean {
        return intent?.action in setOf(Intent.ACTION_PROCESS_TEXT, Intent.ACTION_SEND)
    }

    private fun configureTransparentWindow() {
        window.apply {
            statusBarColor = Color.TRANSPARENT
            navigationBarColor = Color.TRANSPARENT
            setFlags(
                android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
            )
        }
    }

    private fun handleIntent(intent: Intent?) {
        selectedText = when (intent?.action) {
            Intent.ACTION_PROCESS_TEXT -> 
                intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()?.trim()
            Intent.ACTION_SEND -> 
                intent.getStringExtra(Intent.EXTRA_TEXT)?.trim()
            else -> null
        }
    }
}