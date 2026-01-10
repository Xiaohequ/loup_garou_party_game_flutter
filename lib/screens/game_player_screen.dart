import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GamePlayerScreen extends StatefulWidget {
  final String gameUrl;
  final WebViewController? controller;

  const GamePlayerScreen({super.key, required this.gameUrl, this.controller});

  @override
  State<GamePlayerScreen> createState() => _GamePlayerScreenState();
}

class _GamePlayerScreenState extends State<GamePlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _isLoading = true;
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Update loading bar.
            },
            onPageStarted: (String url) {},
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
            onWebResourceError: (WebResourceError error) {},
          ),
        )
        ..loadRequest(Uri.parse(widget.gameUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.admin_panel_settings),
        label: const Text('Menu Host'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }
}
