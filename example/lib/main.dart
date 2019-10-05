import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/model.dart';
import 'package:nearby_connections/nearby_connections.dart';

const String SERVICE_ID = 'SERVICE_ID_1';

enum ConnectionMode { NONE, ADVERTISING, DISCOVERY, CONNECTED }
enum Answers { YES, NO }

const Utf8Encoder encoder = Utf8Encoder();
const Utf8Decoder decoder = Utf8Decoder();

class Connection {
  ConnectionLifecycle lifecycle;
  Discovery discovery;
  double value = 0.0;
}

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ConnectionMode connectionMode = ConnectionMode.NONE;
  final myController = TextEditingController(text: faker.person.name());
  HashMap<String, Connection> connections = HashMap();
  BuildContext dialogContext;
  bool autoAccept = true;
  double value = 0.0;
  HashSet<String> connectedEndpoints = HashSet();

  @override
  void initState() {
    super.initState();
    this.connectionMode = ConnectionMode.NONE;
    NearbyConnections.getDiscoveryStream().listen(_handleDiscoveries);
    NearbyConnections.getConnectionLifecycleStream().listen(_handleConnectionLifecycleChanges);
    NearbyConnections.getPayloadStream().listen(_handlePayloadEvent);
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  void startAdvertise() {
    setState(() {
      connectionMode = ConnectionMode.ADVERTISING;
    });
    NearbyConnections.startAdvertising(strategy: Strategy.P2P_CLUSTER, name: myController.text, idService: SERVICE_ID);
  }

  void stopAdvertise() {
    setState(() {
      connectionMode = ConnectionMode.NONE;
    });
    NearbyConnections.stopAdvertising();
  }

  void startDiscovery() {
    setState(() {
      connectionMode = ConnectionMode.DISCOVERY;
    });
    NearbyConnections.startDiscovery(strategy: Strategy.P2P_CLUSTER, idService: SERVICE_ID);
  }

  void stopDiscover() {
    setState(() {
      connectionMode = ConnectionMode.NONE;
    });
    NearbyConnections.stopDiscovery();
  }

  void stop() {
    if (connectionMode == ConnectionMode.ADVERTISING) {
      stopAdvertise();
    } else if (connectionMode == ConnectionMode.DISCOVERY) {
      stopDiscover();
    }
  }

  void _handleDiscoveries(event) {
    if (event == null) {
      return;
    }
    Discovery discovery = event as Discovery;
    print(discovery);
    setState(() {
      HashMap<String, Connection> newConnections = HashMap.from(connections);
      Connection connection = getConnection(discovery.idEndpoint);
      connection.discovery = discovery;
      if (discovery.type == TypeDiscovery.found) {
        newConnections[discovery.idEndpoint] = connection; // Add to list when endpoint was found
      } else {
        newConnections.remove(discovery.idEndpoint); // Remove from list when endpoint was lost
      }
      connections = newConnections;
    });
  }

  void _handleConnectionLifecycleChanges(event) {
    if (event == null) {
      return;
    }
    ConnectionLifecycle connectionLifecycle = event as ConnectionLifecycle;
    print(connectionLifecycle);
    HashMap<String, Connection> newConnections = HashMap.from(connections);
    Connection connection = getConnection(connectionLifecycle.idEndpoint);
    setState(() {
      connection.lifecycle = connectionLifecycle;
      newConnections[connectionLifecycle.idEndpoint] = connection;
      connections = newConnections;
    });
    // Auto Accept connections when flag is set
    if (connection.lifecycle.type == TypeLifecycle.initiated && autoAccept) {
      NearbyConnections.acceptConnection(connection.lifecycle.idEndpoint);
    }
    if (connection.lifecycle.type == TypeLifecycle.connected) {
      setState(() {
        connectedEndpoints.add(connection.lifecycle.idEndpoint);
      });
    }
    if (connection.lifecycle.type == TypeLifecycle.disconnected) {
      setState(() {
        connectedEndpoints.remove(connection.lifecycle.idEndpoint);
      });
    }
  }

  void _handlePayloadEvent(event) {
    if (event == null) {
      return;
    }
    Payload payload = event as Payload;
    print(payload);
    HashMap<String, Connection> newConnections = HashMap.from(connections);
    Connection connection = getConnection(payload.endpointId);
    setState(() {
      if (payload.bytes != null) {
        String textValue = decoder.convert(payload.bytes);
        connection.value = double.parse(textValue);
      }
      newConnections[payload.endpointId] = connection;
      connections = newConnections;
    });
    // Auto Accept connections when flag is set
    if (connection.lifecycle.type == TypeLifecycle.initiated && autoAccept) {
      NearbyConnections.acceptConnection(connection.lifecycle.idEndpoint);
    }
  }

  Connection getConnection(String idEndpoint) {
    Connection connection = connections[idEndpoint];
    if (connection == null) {
      connection = Connection();
    }
    return connection;
  }

  List<Widget> _buildBody(BuildContext context, HashMap<String, Connection> connections) {
    List<Widget> widgets = [
      Padding(
        padding: EdgeInsets.all(8.0),
        child: TextField(
          controller: myController,
          decoration: InputDecoration(labelText: 'Name'),
          readOnly: connectionMode != ConnectionMode.NONE,
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          RaisedButton(
            child: Text('Advertise'),
            onPressed: startAdvertise,
          ),
          RaisedButton(
            child: Text('Stop'),
            onPressed: stop,
          ),
          RaisedButton(
            child: Text('Discover'),
            onPressed: startDiscovery,
          ),
        ],
      ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
        Text(connectionMode == ConnectionMode.ADVERTISING
            ? 'Advertising'
            : connectionMode == ConnectionMode.DISCOVERY ? 'Discovering' : ''),
        Checkbox(
            value: autoAccept,
            onChanged: (value) => setState(() {
                  autoAccept = value;
                })),
        const Text("Auto Accept"),
      ]),
      Slider(
          label: "Value to share",
          value: value,
          onChanged: (newValue) => setState(() {
                value = newValue;
                _sendToAllConnections(value);
              })),
      Divider(),
    ];
    widgets.addAll(_buildConnectionList(context, connections));
    return widgets;
  }

  void _sendToAllConnections(double value) {
    NearbyConnections.sendPayloads(connectedEndpoints.toList(), encoder.convert(value.toString()));
  }

  List<Widget> _buildConnectionList(BuildContext context, HashMap<String, Connection> connections) {
    this.dialogContext = context;
    if (connections == null || connections.isEmpty) {
      return List<Widget>();
    }
    List<Connection> connectionList = List.from(connections.values);
    List<Widget> widgets = List();
    connectionList.forEach((connection) {
      widgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _buildConnectionRow(connection),
      ));
      widgets.add(LinearProgressIndicator(value: connection.value));
    });
    return widgets;
  }

  List<Widget> _buildConnectionRow(Connection connection) {
    List<Widget> widgets = [
      _buildStatusIcon(connection),
      _buildNameText(connection),
    ];
    widgets.addAll(_buildDisConnectButton(connection));
    return widgets;
  }

  Text _buildNameText(Connection connection) {
    if (connection.discovery != null && connection.discovery.nameEndpoint != null) {
      return Text(connection.discovery.nameEndpoint);
    } else if (connection.lifecycle != null && connection.lifecycle.endpointName != null) {
      return Text(connection.lifecycle.endpointName);
    }
  }

  List<Widget> _buildDisConnectButton(Connection connection) {
    List<Widget> widgets = List();
    if (connection.lifecycle == null ||
        connection.lifecycle.type == TypeLifecycle.disconnected ||
        connection.lifecycle.type == TypeLifecycle.rejected) {
      widgets.add(RaisedButton(
          onPressed: () {
            if (connection.discovery != null) {
              NearbyConnections.requestConnection(myController.text, connection.discovery.idEndpoint);
            } else {
              NearbyConnections.requestConnection(myController.text, connection.lifecycle.idEndpoint);
            }
          },
          child: Text('Connect')));
    } else if (connection.lifecycle.type == TypeLifecycle.connected) {
      widgets.add(RaisedButton(
          onPressed: () {
            _manuallyDisconnectConnection(connection);
          },
          child: Text('Disonnect')));
    } else if (connection.lifecycle.type == TypeLifecycle.initiated) {
      widgets.add(RaisedButton(
          onPressed: () {
            NearbyConnections.acceptConnection(connection.lifecycle.idEndpoint);
          },
          child: Text('Accept')));
      widgets.add(RaisedButton(
          onPressed: () {
            NearbyConnections.rejectConnection(connection.lifecycle.idEndpoint);
          },
          child: Text('Reject')));
    }
    return widgets;
  }

  void _manuallyDisconnectConnection(Connection connection) {
    NearbyConnections.disconnectFromEndpoint(connection.lifecycle.idEndpoint);
    // Our state must be updated manually, as in my tests I did not receive a disconnect event from the plugin
    // after calling above method
    setState(() {
      HashMap<String, Connection> newConnections = HashMap.from(connections);
      connection.lifecycle.type = TypeLifecycle.disconnected;
      newConnections[connection.lifecycle.idEndpoint] = connection;
      connections = newConnections;
      connectedEndpoints.remove(connection.lifecycle.idEndpoint);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Connections Sample'),
        ),
        body: Column(
          children: _buildBody(context, this.connections),
        ),
      ),
    );
  }

  _buildStatusIcon(Connection event) {
    if (event.lifecycle == null) {
      return Icon(Icons.signal_cellular_off);
    }
    switch (event.lifecycle.type) {
      case TypeLifecycle.initiated:
        return Icon(Icons.signal_cellular_null);
        break;
      case TypeLifecycle.connected:
        return Icon(Icons.signal_cellular_4_bar);
        break;
      case TypeLifecycle.disconnected:
        return Icon(Icons.signal_cellular_off);
        break;
      case TypeLifecycle.rejected:
        return Icon(Icons.signal_cellular_connected_no_internet_4_bar);
        break;
    }
  }
}
