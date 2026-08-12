package com.darkmintis.network_simulator.tunnel

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.os.ParcelFileDescriptor
import com.darkmintis.network_simulator.config.TunnelConfig
import com.darkmintis.network_simulator.stack.LocalForwardingPipeline
import com.darkmintis.network_simulator.stack.SocketProtector
import java.net.DatagramSocket
import java.net.Socket
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * App-scoped local VPN service that shapes host-app traffic only.
 */
class NetworkSimulatorVpnService : VpnService() {
    interface Listener {
        fun onStatus(status: String)

        fun onStats(stats: Map<String, Any>)

        fun onError(message: String)
    }

    private val pipelineRef = AtomicReference<LocalForwardingPipeline?>(null)
    private var tunInterface: ParcelFileDescriptor? = null
    private var statsScheduler: ScheduledExecutorService? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopTunnel()
                return START_NOT_STICKY
            }
            ACTION_UPDATE_CONFIG -> {
                val config = intent.extras?.let { TunnelConfigCodec.fromBundle(it) } ?: TunnelConfig()
                pipelineRef.get()?.updateConfig(config)
                return START_STICKY
            }
            else -> {
                val config = intent?.extras?.let { TunnelConfigCodec.fromBundle(it) } ?: TunnelConfig()
                startTunnel(config)
            }
        }
        return START_STICKY
    }

    private fun startTunnel(config: TunnelConfig) {
        try {
            listener?.onStatus("connecting")
            startForeground(NOTIFICATION_ID, buildNotification())

            val builder = Builder()
                .setSession("Network Simulator")
                .setMtu(1500)
                .addAddress(VPN_ADDRESS, 24)
                .addRoute("0.0.0.0", 0)
                .addDnsServer("8.8.8.8")
                .addDnsServer("1.1.1.1")

            runCatching {
                builder.addAllowedApplication(applicationContext.packageName)
            }.onFailure {
                listener?.onError(
                    "Could not scope VPN to ${applicationContext.packageName}: ${it.message}",
                )
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                builder.setMetered(false)
            }

            runCatching { tunInterface?.close() }
            val established = builder.establish()
            if (established == null) {
                listener?.onError("Unable to establish VPN interface")
                listener?.onStatus("error")
                stopSelf()
                return
            }
            tunInterface = established

            val vpnService = this
            val pipeline = LocalForwardingPipeline(
                protector = object : SocketProtector {
                    override fun protect(socket: DatagramSocket): Boolean =
                        vpnService.protect(socket)

                    override fun protect(socket: Socket): Boolean =
                        vpnService.protect(socket)
                },
            )
            pipeline.updateConfig(config)
            pipeline.start(established)
            pipelineRef.set(pipeline)

            statsScheduler?.shutdownNow()
            statsScheduler = Executors.newSingleThreadScheduledExecutor().also { scheduler ->
                scheduler.scheduleAtFixedRate({
                    listener?.onStats(pipeline.stats.snapshot())
                }, 1, 1, TimeUnit.SECONDS)
            }

            listener?.onStatus("connected")
        } catch (error: Exception) {
            listener?.onError(error.message ?: "VPN start failed")
            listener?.onStatus("error")
            stopTunnel()
        }
    }

    private fun stopTunnel() {
        listener?.onStatus("disconnecting")
        statsScheduler?.shutdownNow()
        statsScheduler = null
        pipelineRef.getAndSet(null)?.stop()
        runCatching { tunInterface?.close() }
        tunInterface = null
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
        listener?.onStatus("idle")
    }

    override fun onDestroy() {
        stopTunnel()
        super.onDestroy()
    }

    private fun buildNotification(): Notification {
        val channelId = "network_simulator_vpn"
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Network Simulator",
                NotificationManager.IMPORTANCE_LOW,
            )
            manager.createNotificationChannel(channel)
        }

        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val pending = PendingIntent.getActivity(
            this,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("Network Simulator active")
            .setContentText("Debug traffic shaping tunnel is running")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentIntent(pending)
            .setOngoing(true)
            .build()
    }

    companion object {
        const val ACTION_START = "com.darkmintis.network_simulator.START"
        const val ACTION_STOP = "com.darkmintis.network_simulator.STOP"
        const val ACTION_UPDATE_CONFIG = "com.darkmintis.network_simulator.UPDATE_CONFIG"
        private const val VPN_ADDRESS = "10.0.0.2"
        private const val NOTIFICATION_ID = 7201

        @Volatile
        var listener: Listener? = null

        fun prepareIntent(context: Context): Intent? = prepare(context)

        fun start(context: Context, config: TunnelConfig) {
            val intent = Intent(context, NetworkSimulatorVpnService::class.java).apply {
                action = ACTION_START
                putExtras(TunnelConfigCodec.toBundle(config))
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, NetworkSimulatorVpnService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun updateConfig(context: Context, config: TunnelConfig) {
            val intent = Intent(context, NetworkSimulatorVpnService::class.java).apply {
                action = ACTION_UPDATE_CONFIG
                putExtras(TunnelConfigCodec.toBundle(config))
            }
            context.startService(intent)
        }
    }
}

internal object TunnelConfigCodec {
    fun toBundle(config: TunnelConfig): Bundle = Bundle().apply {
        putString("mode", config.mode)
        putDouble("latencyMs", config.latencyMs)
        putDouble(
            "downloadMbps",
            if (config.downloadMbps.isFinite()) config.downloadMbps else -1.0,
        )
        putDouble(
            "uploadMbps",
            if (config.uploadMbps.isFinite()) config.uploadMbps else -1.0,
        )
        putDouble("jitterMs", config.jitterMs)
        putDouble("packetLoss", config.packetLoss)
        putBoolean("isOffline", config.isOffline)
    }

    fun fromBundle(bundle: Bundle): TunnelConfig {
        return TunnelConfig(
            mode = bundle.getString("mode") ?: "normal",
            latencyMs = bundle.getDouble("latencyMs", 0.0),
            downloadMbps = mbps(bundle.getDouble("downloadMbps", -1.0)),
            uploadMbps = mbps(bundle.getDouble("uploadMbps", -1.0)),
            jitterMs = bundle.getDouble("jitterMs", 0.0),
            packetLoss = bundle.getDouble("packetLoss", 0.0),
            isOffline = bundle.getBoolean("isOffline", false),
        )
    }

    private fun mbps(value: Double): Double =
        if (value < 0) Double.POSITIVE_INFINITY else value
}
