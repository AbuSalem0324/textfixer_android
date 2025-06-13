package com.example.textfixer_android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.textfixer.android/intent"
    private var selectedText: String? = null

    override fun getBackgroundMode(): BackgroundMode {
        // Make Flutter background transparent for text processing intents
        return if (intent?.action == Intent.ACTION_PROCESS_TEXT || intent?.action == Intent.ACTION_SEND) {
            BackgroundMode.transparent
        } else {
            BackgroundMode.opaque
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // If this is a text processing intent, configure for transparency
        if (intent?.action == Intent.ACTION_PROCESS_TEXT || intent?.action == Intent.ACTION_SEND) {
            // Make window transparent
            window.statusBarColor = android.graphics.Color.TRANSPARENT
            window.navigationBarColor = android.graphics.Color.TRANSPARENT
            
            // Don't steal focus
            window.setFlags(
                android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                android.view.WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
            )
        }
        
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getIntentText" -> {
                    android.util.Log.d("TextFixer", "getIntentText called, returning: $selectedText")
                    result.success(selectedText)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        android.util.Log.d("TextFixer", "handleIntent called with action: ${intent?.action}")
        
        when (intent?.action) {
            Intent.ACTION_PROCESS_TEXT -> {
                selectedText = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
                android.util.Log.d("TextFixer", "PROCESS_TEXT: $selectedText")
            }
            Intent.ACTION_SEND -> {
                selectedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                android.util.Log.d("TextFixer", "SEND: $selectedText")
            }
            else -> {
                android.util.Log.d("TextFixer", "Other intent: ${intent?.action}")
            }
        }
    }
}