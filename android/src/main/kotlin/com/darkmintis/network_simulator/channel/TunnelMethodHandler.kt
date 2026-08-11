package com.darkmintis.network_simulator.channel

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.darkmintis.network_simulator.config.TunnelConfig
import com.darkmintis.network_simulator.tunnel.NetworkSimulatorVpnService
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Handles MethodChannel calls and fans out tunnel events to Dart.
 */
class TunnelMethodHandler(
    private val context: Context,
    private val activityProvider: () -> Activity?,
) : MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener,
    NetworkSimulatorVpnService.Listener {

    private var pendingStartResult: MethodChannel.Result? = null
    private var pendingConfig: TunnelConfig? = null

    var statusSink: EventChannel.EventSink? = null
    var statsSink: EventChannel.EventSink? = null
    var errorSink: EventChannel.EventSink? = null

    @Volatile
    private var currentStatus: String = "idle"

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(true)
            "getStatus" -> result.success(currentStatus)
            "startTunnel" -> startTunnel(call, result)
            "stopTunnel" -> {
                NetworkSimulatorVpnService.stop(context)
                result.success(null)
            }
            "updateConfig" -> {
                val config = TunnelConfig.fromMap(call.arguments as? Map<*, *>)
                NetworkSimulatorVpnService.updateConfig(context, config)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun startTunnel(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val config = TunnelConfig.fromMap(args?.get("config") as? Map<*, *>)
        val activity = activityProvider()
        if (activity == null) {
            result.error("no_activity", "Activity required to request VPN permission", null)
            return
        }

        val prepareIntent = NetworkSimulatorVpnService.prepareIntent(activity)
        if (prepareIntent != null) {
            pendingStartResult = result
            pendingConfig = config
            activity.startActivityForResult(prepareIntent, REQUEST_VPN_PERMISSION)
            emitStatus("preparing")
        } else {
            NetworkSimulatorVpnService.listener = this
            NetworkSimulatorVpnService.start(context, config)
            result.success(null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_VPN_PERMISSION) return false
        val result = pendingStartResult
        val config = pendingConfig
        pendingStartResult = null
        pendingConfig = null

        if (resultCode == Activity.RESULT_OK && config != null) {
            NetworkSimulatorVpnService.listener = this
            NetworkSimulatorVpnService.start(context, config)
            result?.success(null)
        } else {
            emitStatus("idle")
            result?.error("permission_denied", "VPN permission was denied", null)
        }
        return true
    }

    override fun onStatus(status: String) {
        emitStatus(status)
    }

    override fun onStats(stats: Map<String, Any>) {
        statsSink?.success(stats)
    }

    override fun onError(message: String) {
        errorSink?.success(message)
    }

    private fun emitStatus(status: String) {
        currentStatus = status
        statusSink?.success(status)
    }

    companion object {
        const val REQUEST_VPN_PERMISSION = 7920
    }
}
