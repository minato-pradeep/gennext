package com.example.bluebug_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device booted, SOS service can be restarted if needed")
            // Note: We don't automatically start services on boot for privacy reasons
            // The service will be started when calls are detected
        }
    }
}