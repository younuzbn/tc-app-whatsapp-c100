package com.example.tc_whatsapp

import android.app.Service
import android.content.Intent
import android.os.IBinder

class SessionWatchService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent) {
        getSharedPreferences(SESSION_PREFS_NAME, MODE_PRIVATE).edit().clear().commit()
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }
}
