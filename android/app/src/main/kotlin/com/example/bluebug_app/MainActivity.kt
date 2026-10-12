package com.example.bluebug_app

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val SOS_CHANNEL = "com.example.bluebug_app/sos"
    private val PREFS_NAME = "sos_prefs"
    private val KEY_PARTNER_NUMBER = "partner_number"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SOS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPartnerNumber" -> {
                        val prefs: SharedPreferences =
                            getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                        val number = prefs.getString(KEY_PARTNER_NUMBER, null)
                        Log.d("SosChannel", "getPartnerNumber -> $number")
                        result.success(number)
                    }

                    "setPartnerNumber" -> {
                        val phoneNumber = call.argument<String>("phoneNumber")
                        if (phoneNumber != null) {
                            val prefs: SharedPreferences =
                                getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            prefs.edit().putString(KEY_PARTNER_NUMBER, phoneNumber).apply()
                            Log.d("SosChannel", "setPartnerNumber -> $phoneNumber")
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGUMENT", "phoneNumber is null", null)
                        }
                    }

                    "triggerSosFromNative" -> {
                        // Placeholder: implement real SOS trigger logic here if needed
                        Log.d("SosChannel", "triggerSosFromNative called")
                        result.success("SOS triggered")
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
