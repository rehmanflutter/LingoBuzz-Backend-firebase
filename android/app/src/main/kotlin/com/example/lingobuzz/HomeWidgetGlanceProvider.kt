package com.lingobuzz.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.app.PendingIntent
import android.widget.RemoteViews
import android.os.Build
import android.util.Log

class HomeWidgetGlanceProvider : AppWidgetProvider() {

    companion object {
        const val TAG = "HomeWidgetProvider"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        Log.d(TAG, "onReceive: ${intent.action}")
        
        when (intent.action) {
            "PLAY_ACTION" -> {
                val word = intent.getStringExtra("word") ?: "Hello"
                
                Log.d(TAG, "🔊 Play button clicked - Speaking word: $word")
                
                // Speak the WORD itself (Bonjour) in English pronunciation
                val textToSpeak = word
                
                // Start TTS Service
                val serviceIntent = Intent(context, TTSService::class.java).apply {
                    putExtra(TTSService.EXTRA_TEXT, textToSpeak)
                }
                
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                    Log.d(TAG, "TTS Service started successfully for: $textToSpeak")
                } catch (e: Exception) {
                    Log.e(TAG, "Error starting TTS Service: ${e.message}")
                }
            }
        }
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
    val word = prefs.getString("word", "Bonjour") ?: "Bonjour"
    val translation = prefs.getString("translation", "Hello") ?: "Hello"

    Log.d("HomeWidgetProvider", "Updating widget - Word: $word, Translation: $translation")

    val views = RemoteViews(context.packageName, R.layout.home_widget_layout)
    
    views.setTextViewText(R.id.headline_title, word)
    views.setTextViewText(R.id.headline_description, translation)

    // Play button - Speaks the WORD (Bonjour) in English pronunciation
    val playIntent = Intent(context, HomeWidgetGlanceProvider::class.java).apply {
        action = "PLAY_ACTION"
        putExtra("word", word)  // Send the word, not translation
    }
    val playPendingIntent = PendingIntent.getBroadcast(
        context,
        appWidgetId * 10 + 1,
        playIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
    )
    views.setOnClickPendingIntent(R.id.bt_play, playPendingIntent)

    // Save button - Opens app
    val saveIntent = Intent(context, MainActivity::class.java).apply {
        action = "SAVE_ACTION"
        putExtra("word", word)
        putExtra("translation", translation)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    val savePendingIntent = PendingIntent.getActivity(
        context,
        appWidgetId * 10 + 2,
        saveIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    views.setOnClickPendingIntent(R.id.bt_save, savePendingIntent)

    // Title click - Opens app
    val openIntent = Intent(context, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    val openPendingIntent = PendingIntent.getActivity(
        context,
        appWidgetId * 10 + 3,
        openIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    views.setOnClickPendingIntent(R.id.headline_title, openPendingIntent)

    appWidgetManager.updateAppWidget(appWidgetId, views)
    Log.d("HomeWidgetProvider", "Widget $appWidgetId updated successfully")
}