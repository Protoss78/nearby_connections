import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nearby_connections/nearby_connections.dart';

import 'main.dart';

class ConnectionRowWidget extends StatelessWidget {
  final Connection _connection;
  final String name;
  final Function disconnectHandler;

  ConnectionRowWidget(this._connection, this.name, this.disconnectHandler);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _buildConnectionRow(_connection),
        ),
        LinearProgressIndicator(value: _connection.value),
      ],
    );
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
    return Text('');
  }

  List<Widget> _buildDisConnectButton(Connection connection) {
    List<Widget> widgets = List();
    if (connection.lifecycle == null ||
        connection.lifecycle.type == TypeLifecycle.disconnected ||
        connection.lifecycle.type == TypeLifecycle.rejected) {
      widgets.add(RaisedButton(
          onPressed: () {
            if (connection.discovery != null) {
              NearbyConnections.requestConnection(name, connection.discovery.idEndpoint);
            } else {
              NearbyConnections.requestConnection(name, connection.lifecycle.idEndpoint);
            }
          },
          child: Text('Connect')));
    } else if (connection.lifecycle.type == TypeLifecycle.connected) {
      widgets.add(RaisedButton(
          onPressed: () {
            NearbyConnections.disconnectFromEndpoint(connection.lifecycle.idEndpoint);
            disconnectHandler(connection);
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
