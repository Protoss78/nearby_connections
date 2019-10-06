# nearby_connections

A Flutter plugin for the Nearby Connections API. Inspired and partially forked from [nearby-connectivity](https://github.com/jozews/nearby-connectivity). 

IMPORTANT:
- Only Android side is implemented so far.
- Any help regarding an iOS adaptation would be very much appreciated.
- Also FILE and STREAM payloads are not supported yet. Only BYTE payloads can be exchanged at the moment.

## Getting Started

### Import package
```dart
import 'package:nearby_connections/nearby_connections.dart';
```

### Start advertising
```dart
NearbyConnections.startAdvertising(strategy: Strategy.P2P_CLUSTER, name: myName, idService: MY_SERVICE_ID);
```

### Listen for connection requests and auto accept them
```dart
NearbyConnections.getConnectionLifecycleStream().listen((connection) { 
  switch (advertise.type) {
    case TypeLifecycle.initiated:
      // accept connection here
      NearbyConnections.acceptConnection(connection.lifecycle.idEndpoint);
      break;
    case TypeLifecycle.result:
      break;
    case TypeLifecycle.disconnected:
      // you are now disconnected
      break;
  }
});
NearbyConnections.startAdvertising(strategy: Strategy.P2P_CLUSTER, name: myName, idService: MY_SERVICE_ID);
```

### Start discovery
```dart
NearbyConnections.startDiscovery(strategy: Strategy.P2P_CLUSTER, idService: MY_SERVICE_ID);
```

### Listen for discovered connections
```dart
NearbyConnections.getDiscoveryStream().listen((discovery) { 
  if (discovery.type == TypeDiscovery.found) {
    // New advertiser discovered
  } else if (discovery.type == TypeDiscovery.lost) {
    // Advertised connection was lost
  }
});

```

### Reject a connection
```dart
NearbyConnections.rejectConnection(endpointId);
```

### Send a payload to a single endpoint
```dart
const Utf8Encoder encoder = Utf8Encoder();
NearbyConnections.sendPayloads(receiverEndpointId, encoder.convert(value.toString()));
```

### Send a payload to multiple endpoints
```dart
const Utf8Encoder encoder = Utf8Encoder();
NearbyConnections.sendPayloads(receiverEndpointIdList, encoder.convert(value.toString()));
```

### Handle incoming payloads
```dart
const Utf8Decoder decoder = Utf8Decoder();
NearbyConnections.getPayloadStream().listen((payload) {
  String textValue = decoder.convert(payload.bytes);
});
```


### Stop advertising
```dart
NearbyConnections.stopAdvertising();
```


### Stop discovery
```dart
NearbyConnections.stopDiscovery();
```


### Disconnect a single endpoint
```dart
NearbyConnections.disconnectFromEndpoint(endpointId);
```

### Stop all connections
```dart
NearbyConnections.stopAllEndpoints();
```