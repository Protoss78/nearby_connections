package at.greenhopper.nearby_connections

import com.google.android.gms.nearby.connection.*
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry

class ConnectionHandler(private var registrar: PluginRegistry.Registrar) : EventChannel.StreamHandler, ConnectionLifecycleCallback() {
    private var eventSink: EventChannel.EventSink? = null
    private var connectionLifecycleChannel: EventChannel
    private var endpoints: HashMap<String, HashMap<String, Any>> = HashMap()

    init {
        this.connectionLifecycleChannel = EventChannel(registrar.messenger(), "at.greenhopper/connection_lifecycle")
        this.connectionLifecycleChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun send(typedLifeCycle: Map<String, Any>) {
        println(typedLifeCycle);
        eventSink?.success(typedLifeCycle)
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }

    override fun onConnectionInitiated(endpointId: String, connectionInfo: ConnectionInfo) {
        val values = hashMapOf(
                "type" to 0, // initiated
                "idEndpoint" to endpointId,
                "endpointName" to connectionInfo.endpointName,
                "authenticationToken" to connectionInfo.authenticationToken,
                "isIncomingConnection" to connectionInfo.isIncomingConnection
        )
        endpoints[endpointId] = values
        this.send(values)
    }

    override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
        val current = endpoints[endpointId]
        var newType = 1 // connected
        if (!result.status.isSuccess) {
            newType = 3 // rejected
        }
        val values = hashMapOf(
                "type" to newType,
                "idEndpoint" to endpointId,
                "endpointName" to (current?.get("endpointName") ?: ""),
                "authenticationToken" to (current?.get("authenticationToken") ?: ""),
                "isIncomingConnection" to (current?.get("isIncomingConnection") ?: false)
        )
        endpoints[endpointId] = values
        this.send(values)
    }

    override fun onDisconnected(endpointId: String) {
        val current = endpoints[endpointId]
        var newType = 2 // disconnected
        val values = hashMapOf(
                "type" to newType,
                "idEndpoint" to endpointId,
                "endpointName" to (current?.get("endpointName") ?: ""),
                "authenticationToken" to (current?.get("authenticationToken") ?: ""),
                "isIncomingConnection" to (current?.get("isIncomingConnection") ?: false)
        )
        endpoints[endpointId] = values
        this.send(values)
    }

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            System.out.println(endpointId)
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            System.out.println(endpointId)
        }
    }
}