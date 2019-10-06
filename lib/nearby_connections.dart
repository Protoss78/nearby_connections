import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Represents the available P2P Strategies in the Nearby Connections API.
class Strategy {
  static Strategy P2P_CLUSTER = Strategy("P2P_CLUSTER");
  static Strategy P2P_STAR = Strategy("P2P_STAR");
  static Strategy P2P_POINT_TO_POINT = Strategy("P2P_POINT_TO_POINT");

  final String type;

  Strategy(this.type);
}

/// Enum that represents the different states of a connection lifecycle
enum TypeLifecycle { initiated, connected, disconnected, rejected }

/// Holds all available information of a connection lifecycle
class ConnectionLifecycle {
  /// The current type of the ConnectionLifecycle
  TypeLifecycle type;
  /// The endpoint id of the connection
  String idEndpoint;
  /// The provided name for the connection
  String endpointName;
  /// The generated authentication token
  String authenticationToken;
  /// True if the connection is incoming (e.g. connection requested)
  bool isIncomingConnection;

  /// Default constructor
  ConnectionLifecycle(
      this.type, this.idEndpoint, this.endpointName, this.authenticationToken, this.isIncomingConnection);

  /// Create instance from a map holding all required values.
  ConnectionLifecycle.fromMap(Map map) {
    this.type = TypeLifecycle.values[map["type"]];
    this.idEndpoint = map["idEndpoint"];
    this.endpointName = map["endpointName"];
    this.authenticationToken = map["authenticationToken"];
    this.isIncomingConnection = map["isIncomingConnection"];
  }
}

/// Represents the type of the discovery object (found or lost an advertiser)
enum TypeDiscovery { found, lost }

/// Holds all information for found or lost advertisers
class Discovery {
  /// The type of the discovery object
  TypeDiscovery type;
  /// The endpoint id of the discovered advertiser
  String idEndpoint;
  /// The provided name of the discovered endpoint
  String nameEndpoint;
  /// True if already accepted
  bool accepted;

  /// Default constructor
  Discovery(this.type, this.idEndpoint, this.nameEndpoint, this.accepted);

  /// Create instance from a map holding all required values.
  Discovery.fromMap(Map map) {
    this.type = TypeDiscovery.values[map["type"]];
    this.idEndpoint = map["idEndpoint"];
    this.nameEndpoint = map["nameEndpoint"];
    this.accepted = map["accepted"];
  }
}

/// Enum that represents the type of the received PayloadEvent
enum PayloadEvent { received, transferred }
/// The payload type that was received (Only BYTES supported at the moment)
enum PayloadType { BYTES, FILE, STREAM }

/// Holds all information of the received Payload
class Payload {
  /// The type of the Payload event
  PayloadEvent eventType;
  /// The type of the actual Payload
  PayloadType type;
  /// The actual Payload as byte array (when event type is BYTES)
  Uint8List bytes;
  /// The total number of bytes
  int totalBytes;
  /// The number of bytes transferred so far
  int bytesTransferred;
  /// The status of the payload
  int status;
  /// The endpoint id that sent the Payload
  String endpointId;
  /// The unique id of the Payload
  int payloadId;

  /// Default constructor
  Payload(this.type, this.bytes, this.totalBytes, this.bytesTransferred, this.status, this.eventType, this.endpointId,
      this.payloadId);

  /// Create instance from a map holding all required values.
  Payload.fromMap(Map map) {
    this.endpointId = map["endpointId"];
    this.eventType = PayloadEvent.values[map["event"]];
    if (map["type"] != null) {
      this.type = PayloadType.values[map["type"]];
    }
    this.payloadId = map["payloadId"];
    if (map["bytes"] != null) {
      this.bytes = Uint8List.fromList(map["bytes"]);
    }
    this.totalBytes = map["totalBytes"];
    this.bytesTransferred = map["bytesTransferred"];
    this.status = map["status"];
  }
}

/// Provides methods to establish and use Nearby Connections
class NearbyConnections {
  static MethodChannel _methodChannel = const MethodChannel('at.greenhopper/nearby_connections');
  static EventChannel _connectionLifecycle = const EventChannel('at.greenhopper/connection_lifecycle');
  static EventChannel _endpointDiscovery = const EventChannel('at.greenhopper/endpoint_discovery');
  static EventChannel _payloadCallback = const EventChannel('at.greenhopper/payload_callback');

  static StreamController<ConnectionLifecycle> _connectionLifecycleController = StreamController<ConnectionLifecycle>();
  static StreamController<Discovery> _discoveryController = StreamController<Discovery>();
  static StreamController<Payload> _payloadController = StreamController<Payload>();
  static var _connectionLifecycleSubscription;
  static var _discoverySubscription;
  static var _payloadSubscription;

  /// Checks if the required permissions have been granted
  static Future<bool> _permissionsGranted() async {
    PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.location);
    if (permission == PermissionStatus.unknown || permission == PermissionStatus.denied) {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler().requestPermissions([PermissionGroup.location]);
      permission = permissions[PermissionGroup.location];
    }
    return permission == PermissionStatus.granted;
  }

  /// Start stream listeners when they have not been started yet
  static void _startStreamHandlingOnce() {
    if (_connectionLifecycleSubscription == null) {
      _connectionLifecycleSubscription = _connectionLifecycle.receiveBroadcastStream().listen((event) {
        _connectionLifecycleController.add(ConnectionLifecycle.fromMap(event));
      });
    }
    if (_discoverySubscription == null) {
      _discoverySubscription = _endpointDiscovery.receiveBroadcastStream().listen((event) {
        _discoveryController.add(Discovery.fromMap(event));
      });
    }
    if (_payloadSubscription == null) {
      _payloadSubscription = _payloadCallback.receiveBroadcastStream().listen((event) {
        _payloadController.add(Payload.fromMap(event));
      });
    }
  }

  /// Returns the payload stream to access data that is shared on all established connections
  static Stream<Payload> getPayloadStream() => _payloadController.stream;

  /// Starts the advertising process. P2P_CLUSTER Strategy is used when no strategy is provided.
  static Stream<ConnectionLifecycle> startAdvertising(
      {Strategy strategy, @required String name, @required String idService}) {
    try {
      _doStartAdvertising(strategy: strategy, name: name, idService: idService);
      _startStreamHandlingOnce();
    } on PlatformException catch (e) {
      print(e);
    }
    return getConnectionLifecycleStream();
  }

  /// Actually starts the advertising process, but checks for the needed permissions before.
  static void _doStartAdvertising({Strategy strategy, String name, String idService}) async {
    if (await _permissionsGranted()) {
      await _methodChannel.invokeMethod('startAdvertising', <String, dynamic>{
        'strategy': strategy.type,
        'name': name,
        'idService': idService,
      });
    }
  }

  /// Provides the connection lifecycle stream to be able to react on the changes to existing or new connections.
  static Stream<ConnectionLifecycle> getConnectionLifecycleStream() => _connectionLifecycleController.stream;

  /// Actually starts the discovery process and checks permissions before that.
  static void _doStartDiscovery({Strategy strategy, String idService}) async {
    if (await _permissionsGranted()) {
      await _methodChannel.invokeMethod('startDiscovery', <String, dynamic>{
        'strategy': strategy.type,
        'idService': idService,
      });
    }
  }

  /// Starts the discovery process. P2P_CLUSTER Strategy is used when no strategy is provided.
  static Stream<Discovery> startDiscovery({Strategy strategy, @required String idService}) {
    try {
      _doStartDiscovery(strategy: strategy, idService: idService);
      _startStreamHandlingOnce();
    } on PlatformException catch (e) {
      print(e);
    }
    return getDiscoveryStream();
  }

  /// Provides the discovery stream to be able to react to new or lost advertisers.
  static Stream<Discovery> getDiscoveryStream() => _discoveryController.stream;

  /// Stops the advertising process.
  static void stopAdvertising() async {
    if (await NearbyConnections._permissionsGranted()) {
      _methodChannel.invokeMethod('stopAdvertising');
    }
  }

  /// Stops the discovery process.
  static void stopDiscovery() async {
    if (await NearbyConnections._permissionsGranted()) {
      _methodChannel.invokeMethod('stopDiscovery');
    }
  }

  /// Request a connection on the passed endpoint id.
  static Future requestConnection(String name, String endpointId) async {
    await _methodChannel.invokeMethod('requestConnection', <String, dynamic>{
      'name': name,
      'endpointId': endpointId,
    });
  }

  /// Accepts an initiated connection process on the specified endpoint id.
  static Future<void> acceptConnection(String endpointId) async {
    if (await NearbyConnections._permissionsGranted()) {
      await _methodChannel.invokeMethod('acceptConnection', <String, dynamic>{
        'endpointId': endpointId,
      });
    }
  }

  /// Rejects an initiated connection process on the specified endpoint id.
  static Future<void> rejectConnection(String endpointId) async {
    if (await NearbyConnections._permissionsGranted()) {
      await _methodChannel.invokeMethod('rejectConnection', <String, dynamic>{
        'endpointId': endpointId,
      });
    }
  }

  /// Disconnect from the endpoint with the provided id.
  static Future<void> disconnectFromEndpoint(String endpointId) async {
    if (await NearbyConnections._permissionsGranted()) {
      await _methodChannel.invokeMethod('disconnectFromEndpoint', <String, dynamic>{
        'endpointId': endpointId,
      });
    }
  }

  /// Sends the provided payload as a byte array to the provided endpoint id.
  static Future<void> sendPayload(String endpointId, Uint8List payload) async {
    if (await NearbyConnections._permissionsGranted()) {
      await _methodChannel.invokeMethod('sendPayload', <String, dynamic>{
        'endpointId': endpointId,
        'payload': payload,
      });
    }
  }

  /// Sends the provided payload as a byte array to the provided list of endpoint id.
  static Future<void> sendPayloads(List<String> endpointIds, Uint8List payload) async {
    if (await NearbyConnections._permissionsGranted()) {
      await _methodChannel.invokeMethod('sendPayloads', <String, dynamic>{
        'endpointIds': endpointIds,
        'payload': payload,
      });
    }
  }

  /// Stops the connections on all currently connected endpoints.
  static void stopAllEndpoints() async {
    if (await NearbyConnections._permissionsGranted()) {
      _methodChannel.invokeMethod('stopAllEndpoints');
    }
  }
}
