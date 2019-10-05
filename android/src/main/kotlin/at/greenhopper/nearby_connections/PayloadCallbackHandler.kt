package at.greenhopper.nearby_connections

import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry

class PayloadCallbackHandler(private var registrar: PluginRegistry.Registrar) : EventChannel.StreamHandler, PayloadCallback() {
    private var eventSink: EventChannel.EventSink? = null
    private var payload_callbackHandler: EventChannel

    init {
        this.payload_callbackHandler = EventChannel(registrar.messenger(), "at.greenhopper/payload_callback")
        this.payload_callbackHandler.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }

    private fun send(message: Map<String, Any?>) {
        println(message)
        eventSink?.success(message)
    }

    override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
        val map = getPayloadMap(endpointId, update)
        //this.send(map)
        println(map)
    }

    override fun onPayloadReceived(endpointId: String, payload: Payload) {
        val map = getPayloadMap(endpointId, payload)
        this.send(map)
    }

    private fun getPayloadMap(endpointId: String, payload: PayloadTransferUpdate): Map<String, Any?> {
        return mapOf("endpointId" to endpointId,
                "payloadId" to payload.payloadId,
                "totalBytes" to payload.totalBytes,
                "bytesTransferred" to payload.bytesTransferred,
                "status" to payload.status,
                "event" to 1) // transferred
    }

    private fun getPayloadMap(endpointId: String, payload: Payload): Map<String, Any?> {
        if (payload.type == Payload.Type.BYTES) {
            return mapOf("endpointId" to endpointId,
                    "payloadId" to payload.id,
                    "type" to 0, // Bytes Payload
                    "bytes" to payload.asBytes()?.toUByteArray(),
                    "event" to 0) // received
        } else if (payload.type == Payload.Type.FILE) {
            // Not implemented yet
            println("Payload.Type.FILE not supported!");
        } else if (payload.type == Payload.Type.STREAM) {
            // Not implemented yet
            println("Payload.Type.STREAM not supported!");
        }
        return HashMap<String, Any?>();
    }

}