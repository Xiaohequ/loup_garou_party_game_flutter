import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../game/game_controller.dart';
import '../game/game_state.dart';

class GameServer {
  HttpServer? _server;
  final List<WebSocketChannel> _clients = [];
  final String staticFilesPath;
  final GameController _gameController = GameController();

  GameServer({required this.staticFilesPath});

  Future<void> start() async {
    // Handler for WebSocket
    final wsHandler = webSocketHandler((WebSocketChannel webSocket) {
      _clients.add(webSocket);
      print('New connection: ${_clients.length} clients');

      _sendState(webSocket);

      webSocket.stream.listen(
        (message) {
          _handleMessage(webSocket, message);
        },
        onDone: () {
          _clients.remove(webSocket);
          print('Connection closed');
        },
        onError: (e) {
          print("WS Error: $e");
          _clients.remove(webSocket);
        },
      );
    });

    // Handler for Static Files
    final staticHandler = createStaticHandler(
      staticFilesPath,
      defaultDocument: 'index.html',
    );

    // Main Handler with manual routing for debug/simplicity
    final handler =
        Pipeline().addMiddleware(logRequests()).addHandler((Request request) {
      // Check for WebSocket route
      if (request.url.path == 'ws') {
        print('Incoming WS request: ${request.method} ${request.url}');
        // Optional: Print headers to debug
        // request.headers.forEach((k, v) => print('$k: $v'));

        return wsHandler(request);
      }
      // Fallback to static files
      return staticHandler(request);
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
    print(
        'Server listening at http://${_server!.address.host}:${_server!.port}');
  }

  void _handleMessage(WebSocketChannel client, dynamic message) {
    try {
      final decoded = jsonDecode(message);
      final type = decoded['type'];
      final payload = decoded['payload'];

      print("Msg: $type $payload");

      switch (type) {
        case 'JOIN':
          final newPlayer = _gameController.addPlayer(payload['name']);
          if (newPlayer != null) {
            client.sink.add(jsonEncode({
              'type': 'PLAYER_INFO',
              'payload': {
                'id': newPlayer.id,
                'name': newPlayer.name,
              }
            }));
          }
          break;
        case 'READY':
          if (payload['playerId'] != null) {
            _gameController.playerReady(payload['playerId']);
          }
          break;
        case 'ACTION':
          if (payload['playerId'] != null && payload['actionType'] != null) {
            _gameController.handleAction(
                payload['playerId'], payload['actionType'], payload);
          }
          break;
      }

      _broadcastState();
    } catch (e) {
      print('Error handling message: $e');
    }
  }

  final _stateController = StreamController<GameState>.broadcast();
  Stream<GameState> get stateStream => _stateController.stream;

  void _broadcastState() {
    final state = _gameController.state;
    _stateController.add(state);

    final stateJson = jsonEncode({
      'type': 'STATE_UPDATE',
      'state': state.toJson(),
    });

    for (var client in _clients) {
      client.sink.add(stateJson);
    }
  }

  void _sendState(WebSocketChannel client) {
    client.sink.add(jsonEncode({
      'type': 'STATE_UPDATE',
      'state': _gameController.state.toJson(),
    }));
  }

  void resetGame() {
    _gameController.resetGame();
    _broadcastState();
  }

  Future<void> stop() async {
    await _server?.close();
    for (var client in _clients) client.sink.close();
    await _stateController.close();
  }

  String get address => _server?.address.address ?? 'Unknown';
  int get port => _server?.port ?? 0;
}
