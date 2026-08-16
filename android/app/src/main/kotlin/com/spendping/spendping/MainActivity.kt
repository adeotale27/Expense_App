package com.spendping.spendping

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "spendping/launch"
    private var launchUri: String? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        launchUri = intent.data?.toString()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launchUri = intent?.data?.toString() ?: launchUri
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                if (call.method == "consumeLaunch") {
                    val value = launchUri ?: intent?.data?.toString()
                    launchUri = null
                    result.success(value)
                } else {
                    result.notImplemented()
                }
            }
    }
}
