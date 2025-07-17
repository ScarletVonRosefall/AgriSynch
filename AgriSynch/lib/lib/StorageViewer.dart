import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageViewerPage extends StatefulWidget {
  const StorageViewerPage({super.key});

  @override
  State<StorageViewerPage> createState() => _StorageViewerPageState();
}

class _StorageViewerPageState extends State<StorageViewerPage> {
  final storage = FlutterSecureStorage();
  Map<String, String> storageData = {};

  @override
  void initState() {
    super.initState();
    loadStorage();
  }

  Future<void> loadStorage() async {
    final all = await storage.readAll();
    setState(() {
      storageData = all;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Storage Viewer')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: loadStorage,
            child: const Text('Refresh'),
          ),
          Expanded(
            child: ListView(
              children: storageData.entries
                  .map((entry) => ListTile(
                        title: Text(entry.key),
                        subtitle: Text(entry.value),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}