package com.lingobuzz.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val BATTERY_CHANNEL = "com.lingobuzz.app/battery"
    private val WIDGET_CHANNEL = "com.lingobuzz.app/widget_settings"
    private val REQUEST_PIN_APPWIDGET = 1002

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Battery optimization channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" -> {
                        result.success(isIgnoringBatteryOptimizations())
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        requestIgnoreBatteryOptimizations()
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }

        // Widget settings channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openWidgetPicker" -> {
                        openWidgetPicker(result)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    /**
     * Open Android widget picker
     * Supports Android 8.0+ (API 26+) with requestPinAppWidget
     */
    private fun openWidgetPicker(result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Android 8.0+ (API 26+): Use requestPinAppWidget
                val appWidgetManager = AppWidgetManager.getInstance(this)
                val myProvider = ComponentName(this, HomeWidgetGlanceProvider::class.java)

                if (appWidgetManager.isRequestPinAppWidgetSupported) {
                    // Create a callback intent (optional)
                    val successCallback = Intent(this, MainActivity::class.java).let { intent ->
                        intent.action = "WIDGET_PINNED"
                        android.app.PendingIntent.getActivity(
                            this,
                            REQUEST_PIN_APPWIDGET,
                            intent,
                            android.app.PendingIntent.FLAG_IMMUTABLE or
                                    android.app.PendingIntent.FLAG_UPDATE_CURRENT
                        )
                    }

                    // Request to pin the widget
                    val pinned = appWidgetManager.requestPinAppWidget(
                        myProvider,
                        null, // No initial bundle
                        successCallback
                    )

                    if (pinned) {
                        println("✅ Widget pin request sent successfully")
                        result.success(true)
                    } else {
                        println("⚠️ Widget pin request not supported or denied")
                        result.success(false)
                    }
                } else {
                    // Launcher doesn't support pinning
                    println("⚠️ Launcher doesn't support widget pinning")
                    result.success(false)
                }
            } else {
                // Android 7.1 and below: Cannot programmatically add widgets
                // Return false so Flutter shows manual instructions
                println("⚠️ Android version < 8.0, showing manual instructions")
                result.success(false)
            }
        } catch (e: Exception) {
            println("❌ Error opening widget picker: ${e.message}")
            e.printStackTrace()
            // Return false to show manual instructions as fallback
            result.success(false)
        }
    }

    /**
     * Handle new intent (for widget callbacks)
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        if (intent.action == "WIDGET_PINNED") {
            println("✅ Widget was successfully pinned!")

            // Optionally notify Flutter
            try {
                val channel = MethodChannel(
                    flutterEngine?.dartExecutor?.binaryMessenger ?: return,
                    WIDGET_CHANNEL
                )
                channel.invokeMethod("widgetPinned", null)
            } catch (e: Exception) {
                println("⚠️ Could not notify Flutter: ${e.message}")
            }
        }
    }

    // Battery optimization methods
    private fun isIgnoringBatteryOptimizations(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val packageName = packageName
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }

    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent()
                val packageName = packageName
                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager

                if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                    intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}