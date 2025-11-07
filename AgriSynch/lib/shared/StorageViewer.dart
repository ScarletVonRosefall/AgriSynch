import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageViewerPage extends StatefulWidget {
  const StorageViewerPage({super.key});

  @override
  State<StorageViewerPage> createState() => _StorageViewerPageState();
}

class _StorageViewerPageState extends State<StorageViewerPage> {
  final storage = FlutterSecureStorage();
  Map<String, String> storageData = {};
  bool _isFixingDatabase = false;

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

  /// Fix products in Firestore that have 'images' field as boolean instead of array
  Future<void> _fixProductImagesInDatabase() async {
    setState(() => _isFixingDatabase = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final productsRef = firestore.collection('products');
      
      // Get all products
      final snapshot = await productsRef.get();
      
      int fixedCount = 0;
      int alreadyCorrect = 0;
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final imagesField = data['images'];
          
          // Check if images field is not a list (could be bool, string, etc.)
          if (imagesField != null && imagesField is! List) {
            // Fix by setting to empty array
            await productsRef.doc(doc.id).update({'images': []});
            fixedCount++;
          } else if (imagesField == null) {
            // If images field is missing, add it
            await productsRef.doc(doc.id).update({'images': []});
            fixedCount++;
          } else {
            alreadyCorrect++;
          }
        } catch (e) {
          print('Error fixing product ${doc.id}: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Fixed $fixedCount products\n'
              '✓ $alreadyCorrect already correct\n'
              'Total: ${snapshot.docs.length}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isFixingDatabase = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Storage Viewer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loadStorage,
                    child: const Text('Refresh Storage'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isFixingDatabase ? null : _fixProductImagesInDatabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: _isFixingDatabase
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Fix Product Images'),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '⚠️ "Fix Product Images" repairs database entries where images field is incorrectly set to boolean instead of array.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView(
              children: storageData.entries
                  .map(
                    (entry) => ListTile(
                      title: Text(entry.key),
                      subtitle: Text(entry.value),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
