package com.lingobuzz.app

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import java.util.Locale

class TTSService : Service(), TextToSpeech.OnInitListener {
    
    private var tts: TextToSpeech? = null
    private var isInitialized = false
    private var pendingText: String? = null
    
    companion object {
        const val EXTRA_TEXT = "text_to_speak"
        const val TAG = "TTSService"
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        tts = TextToSpeech(this, this)
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: "Hello"
        
        Log.d(TAG, "Service started with text: $text")
        
        if (isInitialized) {
            speakText(text)
        } else {
            // Store text to speak after initialization
            pendingText = text
        }
        
        return START_NOT_STICKY
    }
    
    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            // ALWAYS use English US locale for pronunciation
            val result = tts?.setLanguage(Locale.US)
            
            if (result == TextToSpeech.LANG_MISSING_DATA || 
                result == TextToSpeech.LANG_NOT_SUPPORTED) {
                Log.e(TAG, "English language not supported")
            } else {
                isInitialized = true
                Log.d(TAG, "TTS initialized successfully with English US")
                
                // Speak pending text if any
                pendingText?.let { text ->
                    speakText(text)
                    pendingText = null
                }
            }
        } else {
            Log.e(TAG, "TTS initialization failed")
            stopSelf()
        }
    }
    
    private fun speakText(text: String) {
        try {
            // FORCE English US pronunciation
            tts?.setLanguage(Locale.US)
            
            // Set high quality voice parameters
            tts?.setPitch(1.0f)           // Normal pitch
            tts?.setSpeechRate(0.8f)      // Slightly slower for clarity
            
            // Set utterance listener to stop service after speaking
            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    Log.d(TAG, "Started speaking: $text in ENGLISH")
                }
                
                override fun onDone(utteranceId: String?) {
                    Log.d(TAG, "Finished speaking: $text")
                    // Stop service after speaking is done
                    stopSelf()
                }
                
                override fun onError(utteranceId: String?) {
                    Log.e(TAG, "Error speaking: $text")
                    stopSelf()
                }
            })
            
            // Speak with parameters - ALWAYS IN ENGLISH
            val params = HashMap<String, String>()
            params[TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID] = "utteranceId"
            
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, params)
            
            Log.d(TAG, "🔊 Speaking '$text' with English pronunciation")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error speaking: ${e.message}")
            stopSelf()
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        Log.d(TAG, "Service destroyed")
        tts?.stop()
        tts?.shutdown()
        super.onDestroy()
    }
}