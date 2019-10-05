import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'model.dart';

class NearbyConnections {
  static MethodChannel methodChannel = const MethodChannel('at.greenhopper/nearby_connections');
  static EventChannel connection_lifecycle = const EventChannel('at.greenhopper/connection_lifecycle');
  static EventChannel endpoint_discovery = const EventChannel('at.greenhopper/endpoint_discovery');
  static EventChannel payload_callback = const EventChannel('at.greenhopper/payload_callback');

  static StreamController<ConnectionLifecycle> connectionLifecycleController = StreamController<ConnectionLifecycle>();
  static StreamController<Discovery> discoveryController = StreamController<Discovery>();
  static StreamController<Payload> payloadController = StreamController<Payload>();
  static var connectionLifecycleSubscription = null;
  static var discoverySubscription = null;
  static var payloadSubscription = null;

  static Future<bool> permissionsGranted() async {
    PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.location);
    if (permission == PermissionStatus.unknown || permission == PermissionStatus.denied) {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler().requestPermissions([PermissionGroup.location]);
      permission = permissions[PermissionGroup.location];
    }
    return permission == PermissionStatus.granted;
  }

  static Future<bool> _checkPermissions() async {
    return await NearbyConnections.permissionsGranted();
  }

  static void _startStreamHandlingOnce() {
    if (connectionLifecycleSubscription == null) {
      connectionLifecycleSubscription = connection_lifecycle.receiveBroadcastStream().listen((event) {
        print(event);
        ConnectionLifecycle connectionLifecycle = ConnectionLifecycle.fromMap(event);
        connectionLifecycleController.add(connectionLifecycle);
      });
    }
    if (discoverySubscription == null) {
      discoverySubscription = endpoint_discovery.receiveBroadcastStream().listen((event) {
        print(event);
        Discovery discovery = Discovery.fromMap(event);
        discoveryController.add(discovery);
      });
    }
    if (payloadSubscription == null) {
      payloadSubscription = payload_callback.receiveBroadcastStream().listen((event) {
        print(event);
        Payload payload = Payload.fromMap(event);
        payloadController.add(payload);
      });
    }
  }

  static Stream getPayloadStream() => payloadController.stream;

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

  static void _doStartAdvertising({Strategy strategy, String name, String idService}) async {
    if (await _checkPermissions()) {
      await methodChannel.invokeMethod('startAdvertising', <String, dynamic>{
        'strategy': strategy.type,
        'name': name,
        'idService': idService,
      });
    }
  }

  static Stream getConnectionLifecycleStream() => connectionLifecycleController.stream;

  static void _doStartDiscovery({Strategy strategy, String idService}) async {
    if (await _checkPermissions()) {
      await methodChannel.invokeMethod('startDiscovery', <String, dynamic>{
        'strategy': strategy.type,
        'idService': idService,
      });
    }
  }

  static Stream<Discovery> startDiscovery({Strategy strategy, @required String idService}) {
    try {
      _doStartDiscovery(strategy: strategy, idService: idService);
      _startStreamHandlingOnce();
    } on PlatformException catch (e) {
      print(e);
    }
    return getDiscoveryStream();
  }

  static Stream getDiscoveryStream() => discoveryController.stream;

  static void stopAdvertising() async {
    if (await NearbyConnections.permissionsGranted()) {
      methodChannel.invokeMethod('stopAdvertising');
    }
  }

  static void stopDiscovery() async {
    if (await NearbyConnections.permissionsGranted()) {
      methodChannel.invokeMethod('stopDiscovery');
    }
  }

  static Future requestConnection(String name, String endpointId) async {
    await methodChannel.invokeMethod('requestConnection', <String, dynamic>{
      'name': name,
      'endpointId': endpointId,
    });
  }

  static Future<void> acceptConnection(String endpointId) async {
    if (await NearbyConnections.permissionsGranted()) {
      await methodChannel.invokeMethod('acceptConnection', <String, dynamic>{
        'endpointId': endpointId,
      });
    }
  }

  static Future<void> rejectConnection(String endpointId) async {
    if (await NearbyConnections.permissionsGranted()) {
      await methodChannel.invokeMethod('rejectConnection', <String, dynamic>{
        'endpointId': endpointId,
      });
    }
  }

  static Future<void> disconnectFromEndpoint(String endpointId) async {
    if (await NearbyConnections.permissionsGranted()) {
      await methodChannel.invokeMethod('disconnectFromEndpoint', <String, dynamic>{
        'endpointId': endpointId,
      });
    }
  }

  static Future<void> sendPayload(String endpointId, Uint8List payload) async {
    if (await NearbyConnections.permissionsGranted()) {
      await methodChannel.invokeMethod('sendPayload', <String, dynamic>{
        'endpointId': endpointId,
        'payload': payload,
      });
    }
  }

  static Future<void> sendPayloads(List<String> endpointIds, Uint8List payload) async {
    if (await NearbyConnections.permissionsGranted()) {
      await methodChannel.invokeMethod('sendPayloads', <String, dynamic>{
        'endpointIds': endpointIds,
        'payload': payload,
      });
    }
  }

  static void stopAllEndpoints() async {
    if (await NearbyConnections.permissionsGranted()) {
      methodChannel.invokeMethod('stopAllEndpoints');
    }
  }
}
