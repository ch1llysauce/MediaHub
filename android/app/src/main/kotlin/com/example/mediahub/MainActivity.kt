package com.example.mediahub

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.annotation.RequiresApi
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val SETTINGS_CHANNEL = "com.example.mediahub/pip_settings"
    private val CONTROLS_CHANNEL = "com.example.mediahub/pip_controls"

    private var methodChannel: MethodChannel? = null

    private var isPipAutoEnterEnabled = false

    companion object {
        const val ACTION_PIP_PLAY = "com.example.mediahub.PIP_PLAY"
        const val ACTION_PIP_PAUSE = "com.example.mediahub.PIP_PAUSE"
        const val REQUEST_PLAY = 1
        const val REQUEST_PAUSE = 2
    }

    private val pipActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            android.util.Log.d("PiP", "Received action: ${intent?.action}")
            when (intent?.action) {
                ACTION_PIP_PLAY -> methodChannel?.invokeMethod("onPipAction", "play")
                ACTION_PIP_PAUSE -> methodChannel?.invokeMethod("onPipAction", "pause")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Existing: PiP settings opener
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openPipSettings") {
                try {
                    val intent = Intent(
                        "android.settings.PICTURE_IN_PICTURE_SETTINGS",
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    try {
                        val fallbackIntent = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(fallbackIntent)
                        result.success(true)
                    } catch (e2: Exception) {
                        result.error("UNAVAILABLE", "Could not open PiP settings", null)
                    }
                }
            } else {
                result.notImplemented()
            }
        }

        // PiP play/pause controls and auto-enter status
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROLS_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updatePipActions" -> {
                    val playing = call.argument<Boolean>("isPlaying") ?: false
                    updatePipParams(playing)
                    result.success(true)
                }
                "setPipAutoEnter" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    setPipAutoEnter(enabled)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val filter = IntentFilter().apply {
            addAction(ACTION_PIP_PLAY)
            addAction(ACTION_PIP_PAUSE)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(pipActionReceiver, filter)
        }
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(pipActionReceiver)
        } catch (e: Exception) {
            // already unregistered, safe to ignore
        }
        super.onDestroy()
    }

    override fun onPause() {
        super.onPause()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && !isInPictureInPictureMode) {
            if (!isPipAutoEnterEnabled) {
                setPipAutoEnter(false)
            }
        }
    }

    fun setPipAutoEnter(enabled: Boolean) {
        isPipAutoEnterEnabled = enabled
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val params = PictureInPictureParams.Builder()
                    .setAutoEnterEnabled(enabled)
                    .build()
                setPictureInPictureParams(params)
            } catch (e: Exception) {
                android.util.Log.e("PiP", "Error setting auto enter params: ${e.message}")
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun updatePipParams(playing: Boolean) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_IMMUTABLE
        else
            0

        val actions = mutableListOf<RemoteAction>()

        if (playing) {
            val pauseIntent = PendingIntent.getBroadcast(
                this, REQUEST_PAUSE, Intent(ACTION_PIP_PAUSE).setPackage(packageName), flags
            )
            actions.add(
                RemoteAction(
                    Icon.createWithResource(this, android.R.drawable.ic_media_pause),
                    "Pause",
                    "Pause",
                    pauseIntent
                )
            )
        } else {
            val playIntent = PendingIntent.getBroadcast(
                this, REQUEST_PLAY, Intent(ACTION_PIP_PLAY).setPackage(packageName), flags
            )
            actions.add(
                RemoteAction(
                    Icon.createWithResource(this, android.R.drawable.ic_media_play),
                    "Play",
                    "Play",
                    playIntent
                )
            )
        }

        val builder = PictureInPictureParams.Builder()
            .setActions(actions)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(isPipAutoEnterEnabled)
        }

        try {
            setPictureInPictureParams(builder.build())
        } catch (e: Exception) {
            // Activity might not be in a valid state yet — safe to ignore
        }
    }
}