package com.spendping.spendping

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val launchName = "spendping/launch"
    private val widgetName = "spendping/widget"
    private var launchChannel: MethodChannel? = null
    private var launchUri: String? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val uri = intent.data?.toString()
        if (!uri.isNullOrBlank()) {
            launchUri = uri
            launchChannel?.invokeMethod("opened", uri)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launchUri = intent?.data?.toString() ?: launchUri
        launchChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, launchName)
        launchChannel?.setMethodCallHandler { call, result ->
            if (call.method == "consumeLaunch") {
                val value = launchUri ?: intent?.data?.toString()
                launchUri = null
                result.success(value)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "publishToday" -> {
                        val total = call.argument<String>("total") ?: "₹0"
                        QuickAddWidget.publishToday(this, total)
                        result.success(null)
                    }
                    "mapsKey" -> {
                        val appInfo = packageManager.getApplicationInfo(
                            packageName,
                            android.content.pm.PackageManager.GET_META_DATA
                        )
                        val key = appInfo.metaData?.getString("com.google.android.geo.API_KEY")
                        result.success(key)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
