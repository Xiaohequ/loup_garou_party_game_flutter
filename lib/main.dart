import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'server/game_server.dart';

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
  String _serverInfo = 'Initializing...';
  String _serverAddress = '';

  @override
  void initState() {
    super.initState();
    _initAndStartServer();
  }

  Future<void> _initAndStartServer() async {
    try {
      final staticPath = await _extractWebAssets();
      _server = GameServer(staticFilesPath: staticPath);
      await _server!.start();

      setState(() {
        _serverAddress = "http://${_server!.address}:${_server!.port}";
        _serverInfo = 'Server running at\n$_serverAddress\n\nScan to join!';
      });
    } catch (e, stack) {
      print(e);
      print(stack);
      setState(() {
        _serverInfo = 'Failed to start server: $e';
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
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final webAssets =
        manifestMap.keys.where((key) => key.startsWith('assets/web/')).toList();

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _serverInfo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            if (_serverAddress.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  // Logic to copy or share
                  Clipboard.setData(ClipboardData(text: _serverAddress));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address copied!')),
                  );
                },
                child: const Text('Copy Link'),
              )
          ],
        ),
      ),
    );
  }
}
