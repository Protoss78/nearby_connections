package at.greenhopper.nearby_connections

import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class NearbyConnectionsPlugin : MethodCallHandler {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            if (registrar.activity() == null) {
                // If a background flutter view tries to register the plugin, there will be no activity from the registrar,
                // we stop the registering process immediately because we require an activity.
                return
            }
            System.out.println("registerWith")
            this.discoveryHandler = DiscoveryHandler(registrar)
            this.connectionHandler = ConnectionHandler(registrar)
            this.registrar = registrar
            this.methodChannel = MethodChannel(registrar.messenger(), "at.greenhopper/nearby_connections")
            this.methodChannel.setMethodCallHandler(NearbyConnectionsPlugin())
            this.connectionsClient = Nearby.getConnectionsClient(registrar.activity())
            this.payloadCallback = PayloadCallbackHandler(registrar)
        }

        lateinit var discoveryHandler: DiscoveryHandler
        lateinit var connectionHandler: ConnectionHandler
        lateinit var registrar: Registrar
        lateinit var methodChannel: MethodChannel
        lateinit var connectionsClient: ConnectionsClient
        lateinit var payloadCallback: PayloadCallback

    }

    private fun startAdvertising(strategy: Strategy, name: String, serviceId: String) {
        try {
            val advertisingOptions = AdvertisingOptions.Builder().setStrategy(strategy).build()
            Nearby.getConnectionsClient(registrar.activity())
                    .startAdvertising(name, serviceId, connectionHandler, advertisingOptions)
                    .addOnSuccessListener {
                        println("Advertising")
                    }.addOnFailureListener { e: Exception ->
                        println("Error while advertising: {$e}")
                    }
        } catch (e: java.lang.Exception) {
            System.out.println(e.localizedMessage)
        }
    }

    private fun stopAdvertising() {
        Nearby.getConnectionsClient(registrar.activity()).stopAdvertising()
    }

    private fun startDiscovery(strategy: Strategy, idService: String) {
        Nearby.getConnectionsClient(registrar.activity()).startDiscovery(
                idService, discoveryHandler,
                DiscoveryOptions.Builder().setStrategy(strategy).build())
    }

    private fun stopDiscovery() {
        Nearby.getConnectionsClient(registrar.activity()).stopDiscovery()
    }

    private fun requestConnection(name: String, endpointId: String) {
        try {
            Nearby.getConnectionsClient(registrar.activity())
                    .requestConnection(name, endpointId, connectionHandler)
                    .addOnSuccessListener { print("Connected!!") }
        } catch (e: java.lang.Exception) {
            System.out.println(e.localizedMessage)
        }
    }

    private fun acceptConnection(endpointId: String) {
        try {
            Nearby.getConnectionsClient(registrar.activity()).acceptConnection(endpointId, payloadCallback)
        } catch (e: java.lang.Exception) {
            System.out.println(e.localizedMessage)
        }
    }

    private fun rejectConnection(endpointId: String) {
        try {
            Nearby.getConnectionsClient(registrar.activity()).rejectConnection(endpointId)
        } catch (e: java.lang.Exception) {
            System.out.println(e.localizedMessage)
        }
    }

    private fun cancelPayload(payloadId: Long) {
        try {
            Nearby.getConnectionsClient(registrar.activity()).cancelPayload(payloadId)
        } catch (e: java.lang.Exception) {
            System.out.println(e.localizedMessage)
        }
    }

    private fun disconnectFromEndpoint(endpointId: String) {
        try {
            Nearby.getConnectionsClient(registrar.activity()).disconnectFromEndpoint(endpointId)
        } catch (e: java.lang.Exception) {
            System.out.println(e.localizedMessage)
        }
    }

    private fun sendPayload(endpointId: String, payload: Payload) {
        try {
            Nearby.getConnectionsClient(registrar.activity()).sendPayload(endpointId, payload)
        } catch (e: java.lang.Exception) {
            System.out.println(e.localizedMessage)
        }
    }

    private fun sendPayload(endpointIds: List<String>, payload: Payload) {
        try {
            Nearby.getConnectionsClient(registrar.activity()).sendPayload(endpointIds, payload)
        } catch (e: java.lang.Exception) {
            System.out.println(e.localizedMessage)
        }
    }

    private fun stopAllEndpoints() {
        try {
            Nearby.getConnectionsClient(registrar.activity()).stopAllEndpoints()
        } catch (e: java.lang.Exception) {
            System.out.println(e.localizedMessage)
        }
    }

    private fun buildStrategyFromString(value: String): Strategy {
        when {
            value == "P2P_CLUSTER" -> return Strategy.P2P_CLUSTER
            value == "P2P_POINT_TO_POINT" -> return Strategy.P2P_POINT_TO_POINT
            value == "P2P_STAR" -> return Strategy.P2P_STAR
            else -> return Strategy.P2P_CLUSTER;
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        println("Method: " + call.method + ", arguments: " + call.arguments.toString());
        when {
            call.method == "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            call.method == "startAdvertising" -> {
                startAdvertising(
                        buildStrategyFromString(call.argument<String>("strategy") as String),
                        call.argument<String>("name") as String,
                        call.argument<String>("idService") as String)
                result.success(null)
            }
            call.method == "requestConnection" -> {
                requestConnection(
                        call.argument<String>("name") as String,
                        call.argument<String>("endpointId") as String)
                result.success(null)
            }
            call.method == "acceptConnection" -> {
                acceptConnection(call.argument<String>("endpointId") as String)
                result.success(null)
            }
            call.method == "rejectConnection" -> {
                rejectConnection(call.argument<String>("endpointId") as String)
                result.success(null)
            }
            call.method == "disconnectFromEndpoint" -> {
                disconnectFromEndpoint(call.argument<String>("endpointId") as String)
                result.success(null)
            }
            call.method == "sendPayload" -> {
                sendPayload(
                        call.argument<String>("endpointId") as String,
                        Payload.fromBytes(call.argument<ByteArray>("payload") as ByteArray))
                result.success(null)
            }
            call.method == "sendPayloads" -> {
                sendPayload(
                        call.argument<List<String>>("endpointIds") as List<String>,
                        Payload.fromBytes(call.argument<ByteArray>("payload") as ByteArray))
                result.success(null)
            }
            call.method == "stopAllEndpoints" -> {
                stopAllEndpoints()
                result.success(null)
            }
            call.method == "cancelPayload" -> {
                cancelPayload(call.argument<String>("payloadId") as Long)
                result.success(null)
            }
            call.method == "stopAdvertising" -> {
                stopAdvertising()
                result.success(null)
            }
            call.method == "startDiscovery" -> {
                startDiscovery(
                        buildStrategyFromString(call.argument<String>("strategy") as String),
                        call.argument<String>("idService") as String)
                result.success(null)
            }
            call.method == "stopDiscovery" -> {
                stopDiscovery()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}

