import 'dart:typed_data';

class Strategy {
  static Strategy P2P_CLUSTER = Strategy("P2P_CLUSTER");
  static Strategy P2P_STAR = Strategy("P2P_STAR");
  static Strategy P2P_POINT_TO_POINT = Strategy("P2P_POINT_TO_POINT");

  final String type;

  Strategy(this.type);
}

enum TypeLifecycle { initiated, connected, disconnected, rejected }

class ConnectionLifecycle {
  TypeLifecycle type;
  String idEndpoint;
  String endpointName;
  String authenticationToken;
  bool isIncomingConnection;

  ConnectionLifecycle(
      this.type, this.idEndpoint, this.endpointName, this.authenticationToken, this.isIncomingConnection);

  ConnectionLifecycle.fromMap(Map map) {
    this.type = TypeLifecycle.values[map["type"]];
    this.idEndpoint = map["idEndpoint"];
    this.endpointName = map["endpointName"];
    this.authenticationToken = map["authenticationToken"];
    this.isIncomingConnection = map["isIncomingConnection"];
  }
}

enum TypeDiscovery { found, lost }

class Discovery {
  TypeDiscovery type;
  String idEndpoint;
  String nameEndpoint;
  bool accepted;

  Discovery(this.type, this.idEndpoint, this.nameEndpoint, this.accepted);

  Discovery.fromMap(Map map) {
    this.type = TypeDiscovery.values[map["type"]];
    this.idEndpoint = map["idEndpoint"];
    this.nameEndpoint = map["nameEndpoint"];
    this.accepted = map["accepted"];
  }
}

enum PayloadEvent { received, transferred }
enum PayloadType { BYTES, FILE, STREAM }

class Payload {
  PayloadEvent eventType;
  PayloadType type;
  Uint8List bytes;
  int totalBytes;
  int bytesTransferred;
  int status;
  String endpointId;
  int payloadId;

  Payload(this.type, this.bytes, this.totalBytes, this.bytesTransferred, this.status, this.eventType, this.endpointId, this.payloadId);

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
