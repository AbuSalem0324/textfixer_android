package com.example.textfixer_android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.widget.Toast

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.textfixer.android/intent"
    private var selectedText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Show toast to confirm our MainActivity is running
        Toast.makeText(this, "TextFixer MainActivity loaded", Toast.LENGTH_SHORT).show()
        
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
                Toast.makeText(this, "Text received: $selectedText", Toast.LENGTH_LONG).show()
            }
            Intent.ACTION_SEND -> {
                selectedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                android.util.Log.d("TextFixer", "SEND: $selectedText")
                Toast.makeText(this, "Shared text: $selectedText", Toast.LENGTH_LONG).show()
            }
            else -> {
                android.util.Log.d("TextFixer", "Other intent: ${intent?.action}")
            }
        }
    }
}