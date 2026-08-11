package com.darkmintis.network_simulator

import android.app.Activity
import com.darkmintis.network_simulator.channel.TunnelMethodHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin entry point for the Android local VPN tunnel.
 */
class NetworkSimulatorPlugin : FlutterPlugin, ActivityAware {
    private var methodChannel: MethodChannel? = null
    private var statusChannel: EventChannel? = null
    private var statsChannel: EventChannel? = null
    private var errorChannel: EventChannel? = null
    private var handler: TunnelMethodHandler? = null
    private var activityBinding: ActivityPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        handler = TunnelMethodHandler(context) { activityBinding?.activity }

        methodChannel = MethodChannel(binding.binaryMessenger, "network_simulator/tunnel").also {
            it.setMethodCallHandler(handler)
        }
        statusChannel = EventChannel(binding.binaryMessenger, "network_simulator/tunnel_status").also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    handler?.statusSink = events
                }

                override fun onCancel(arguments: Any?) {
                    handler?.statusSink = null
                }
            })
        }
        statsChannel = EventChannel(binding.binaryMessenger, "network_simulator/tunnel_stats").also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    handler?.statsSink = events
                }

                override fun onCancel(arguments: Any?) {
                    handler?.statsSink = null
                }
            })
        }
        errorChannel = EventChannel(binding.binaryMessenger, "network_simulator/tunnel_errors").also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    handler?.errorSink = events
                }

                override fun onCancel(arguments: Any?) {
                    handler?.errorSink = null
                }
            })
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        statusChannel?.setStreamHandler(null)
        statsChannel?.setStreamHandler(null)
        errorChannel?.setStreamHandler(null)
        methodChannel = null
        statusChannel = null
        statsChannel = null
        errorChannel = null
        handler = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        handler?.let { binding.addActivityResultListener(it) }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun detachActivity() {
        handler?.let { activityBinding?.removeActivityResultListener(it) }
        activityBinding = null
    }
}
