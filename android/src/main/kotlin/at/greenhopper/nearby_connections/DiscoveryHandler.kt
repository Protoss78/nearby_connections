package at.greenhopper.nearby_connections

import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Strategy
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry

class DiscoveryHandler(private var registrar: PluginRegistry.Registrar) : EventChannel.StreamHandler, EndpointDiscoveryCallback() {
    private var eventSink: EventChannel.EventSink? = null
    private var endpoint_discoveryChannel: EventChannel

    init {
        this.endpoint_discoveryChannel = EventChannel(registrar.messenger(), "at.greenhopper/endpoint_discovery")
        this.endpoint_discoveryChannel.setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
    }

    fun send(discoveryInfo: Map<String, Any>) {
        println(discoveryInfo);
        eventSink?.success(discoveryInfo)
    }

    override fun onCancel(p0: Any?) {
        eventSink = null
    }

    override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
        val values = hashMapOf("type" to 0, "idEndpoint" to endpointId, "nameEndpoint" to info.endpointName, "accepted" to false)
        System.out.println("onEndpointFound: $values")
        this.send(values)
    }

    override fun onEndpointLost(endpointId: String) {
        val values = hashMapOf("type" to 1, "idEndpoint" to endpointId, "nameEndpoint" to "", "accepted" to false)
        System.out.println("onEndpointLost: $values")
        this.send(values)
    }
}