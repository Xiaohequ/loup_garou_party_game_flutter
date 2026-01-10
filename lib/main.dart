import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';


import 'server/game_server.dart';
import 'game/game_state.dart';
import 'screens/game_player_screen.dart';

void main() {
  runApp(const LoupGarouApp());
}

class LoupGarouApp extends StatelessWidget {
  const LoupGarouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loup Garou Host',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HostHomePage(),
    );
  }
}

class HostHomePage extends StatefulWidget {
  const HostHomePage({super.key});

  @override
  State<HostHomePage> createState() => _HostHomePageState();
}

class _HostHomePageState extends State<HostHomePage> {
  GameServer? _server;
  String _serverAddress = '';
  GameState? _currentState;
  WebViewController? _hostPlayerController;


  @override
  void initState() {
    super.initState();
    _initAndStartServer();
  }

  Future<void> _initAndStartServer() async {
    print("_initAndStartServer");
    try {
      final staticPath = await _extractWebAssets();
      _server = GameServer(staticFilesPath: staticPath);
      await _server!.start();

      print("getLocalIp start");
      final localIp = await GameServer.getLocalIp();
      print("getLocalIp end");

      _server!.stateStream.listen((state) {
        setState(() {
          _currentState = state;
        });
      });

      setState(() {
        _serverAddress = "http://$localIp:${_server!.port}";
      });

      // Initialize host player controller
      _hostPlayerController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..loadRequest(Uri.parse(_serverAddress));

    } catch (e, stack) {
      print(e);
      print(stack);
      setState(() {
        // _serverInfo = 'Failed to start server: $e';
      });
    }
  }

  Future<String> _extractWebAssets() async {
    // Get the documents directory
    final docDir = await getApplicationDocumentsDirectory();
    final webDir = Directory(p.join(docDir.path, 'web'));

    // Re-create the directory to ensure clean state (optional, maybe just overwrite)
    if (await webDir.exists()) {
      await webDir.delete(recursive: true);
    }
    await webDir.create(recursive: true);

    // Load AssetManifest to find all files in assets/web/
    List<String> webAssets = [];
    try {
      final AssetManifest assetManifest =
          await AssetManifest.loadFromAssetBundle(rootBundle);
      webAssets = assetManifest
          .listAssets()
          .where((key) => key.startsWith('assets/web/'))
          .toList();
    } catch (e) {
      print("Warning: Could not load AssetManifest using official API: $e");
      // Fallback for older versions or if manifest is missing
      try {
        final manifestContent =
            await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestContent);
        webAssets = manifestMap.keys
            .where((key) => key.startsWith('assets/web/'))
            .toList();
      } catch (e2) {
        print("Error: Fallback manifest loading also failed: $e2");
        rethrow;
      }
    }

    for (final assetPath in webAssets) {
      // assetPath is like 'assets/web/index.html' or 'assets/web/assets/index.js'
      // We want to extract it to webDir preserving relative path from 'assets/web/'

      // Remove 'assets/web/' prefix
      final relativePath = assetPath.substring('assets/web/'.length);
      if (relativePath.isEmpty) continue; // Skip the folder itself if listed

      final file = File(p.join(webDir.path, relativePath));

      await file.parent.create(recursive: true);

      final data = await rootBundle.load(assetPath);
      await file.writeAsBytes(data.buffer.asUint8List());
    }

    return webDir.path;
  }

  @override
  void dispose() {
    _server?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loup Garou Host'),
      ),
      body: Row(
        children: [
          // Sidebar: Connection Info & Controls
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.deepPurple.shade50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '1. Connect to same Wi-Fi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '2. Scan to Join:',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (_serverAddress.isNotEmpty)
                          Container(
                            color: Colors.white,
                            child: QrImageView(
                              data: _serverAddress,
                              version: QrVersions.auto,
                              size: 80.0,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          _serverAddress,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(), 
                  if (_serverAddress.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _server?.forceNextPhase();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Phase Forced!')),
                          );
                        },
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Force Phase'),
                      ),
                    ),
                  if (_serverAddress.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _server?.resetGame();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Game Reset!')),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Game'),
                      ),
                    ),
                  if (_serverAddress.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => GamePlayerScreen(
                                gameUrl: _serverAddress,
                                controller: _hostPlayerController,
                              ),
                            ),
                          );

                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Rejoindre (Joueur)'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Main Content: Player List
          Expanded(
            flex: 5,
            child: _currentState == null
                ? const Center(child: Text("Waiting for players..."))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Players (${_currentState!.players.length}) - Phase: ${_currentState!.phase.name}" +
                              (_currentState!.phase == GamePhase.end
                                  ? " - WINNER: ${_currentState!.winner.name.toUpperCase()}!"
                                  : ""),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _currentState!.players.length,
                          itemBuilder: (context, index) {
                            final player = _currentState!.players[index];
                            // Calculate votes received
                            final votesReceived = _currentState!.votes.values
                                .where((id) => id == player.id)
                                .length;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    player.isAlive ? Colors.green : Colors.red,
                                child: Icon(
                                  player.isAlive
                                      ? Icons.favorite
                                      : Icons.dangerous,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                player.name,
                                style: TextStyle(
                                  decoration: player.isAlive
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Text(
                                  "Role: ${player.role.name} ${!player.isReady ? '(Not Ready)' : ''}" +
                                      (_currentState!.phase == GamePhase.vote
                                          ? " | Votes: $votesReceived"
                                          : "")),
                              trailing: player.isAlive
                                  ? PopupMenuButton<String>(
                                      onSelected: (value) {
                                        if (value == 'kill') {
                                          _server?.killPlayer(player.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'kill',
                                          child: Text('Kill Player'),
                                        ),
                                      ],
                                      icon: const Icon(Icons.more_vert),
                                    )
                                  : const Text("DEAD",
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
