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
  static Future<String> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return '127.0.0.1';
  }

  HttpServer? _server;
  Timer? _timer;
  final List<WebSocketChannel> _clients = [];
  final Map<String, WebSocketChannel> _playerChannels = {};
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
          _playerChannels.removeWhere((id, ws) => ws == webSocket);
          print('Connection closed');
        },
        onError: (e) {
          print("WS Error: $e");
          _clients.remove(webSocket);
          _playerChannels.removeWhere((id, ws) => ws == webSocket);
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

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameController.state.isTransitioning) {
        _gameController.tickCountdown();
        _broadcastState();
      }
    });
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
            _playerChannels[newPlayer.id] = client;
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

  void forceNextPhase() {
    _gameController.forceNextPhase();
    _broadcastState();
  }

  void killPlayer(String playerId) {
    _gameController.killPlayer(playerId);
    _broadcastState();
  }

  void kickPlayer(String playerId) {
    _gameController.removePlayer(playerId);
    final channel = _playerChannels.remove(playerId);
    if (channel != null) {
      channel.sink.close();
      _clients.remove(channel);
    }
    _broadcastState();
  }

  Future<void> stop() async {
    _timer?.cancel();
    await _server?.close();

    for (var client in _clients) client.sink.close();
    await _stateController.close();
  }

  String get address {
    final serverAddr = _server?.address.address;
    if (serverAddr == '0.0.0.0' || serverAddr == '::') {
      // Return a placeholder or we will handle this in UI if needed,
      // but let's try to return the best address here.
      return 'localhost';
    }
    return serverAddr ?? 'Unknown';
  }

  int get port => _server?.port ?? 0;
}
