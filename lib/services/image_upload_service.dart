import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'rate_limit_service.dart';

class ImageUploadService {
  // Try to use default instance first, will auto-detect bucket
  late final FirebaseStorage _storage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  ImageUploadService() {
    try {
      // Try default instance first
      _storage = FirebaseStorage.instance;
    } catch (e) {
      debugPrint('⚠️ Using default storage failed, trying with explicit bucket...');
      // Fallback to explicit bucket
      _storage = FirebaseStorage.instanceFor(
        bucket: 'gs://agrisynch-a9350.appspot.com',
      );
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return images;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  /// Upload image to Firebase Storage (works on both Web and Mobile)
  Future<String?> uploadProductImage(XFile imageFile, String productId) async {
    if (currentUserId == null) {
      debugPrint('❌ Error: User not authenticated');
      throw Exception('User not authenticated. Please login again.');
    }

    // Check rate limit
    final canUpload = await RateLimitService.checkRateLimit(
      'image_upload',
      userId: currentUserId,
    );
    if (!canUpload) {
      final errorMessage = RateLimitService.getRateLimitMessage('image_upload');
      debugPrint('🚫 ImageUploadService: $errorMessage');
      throw Exception(errorMessage);
    }

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final String filePath = 'products/$currentUserId/$productId/$fileName';
      
      debugPrint('📤 Starting upload to: $filePath (Platform: ${kIsWeb ? "Web" : "Mobile"})');
      debugPrint('👤 Current User ID: $currentUserId');
      
      final Reference ref = _storage.ref().child(filePath);
      
      // Upload file with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'productId': productId},
      );
      
      // Read image as bytes (works on both web and mobile)
      final bytes = await imageFile.readAsBytes();
      
      debugPrint('📦 Image size: ${bytes.length} bytes');
      
      // Upload bytes directly (compatible with web and mobile)
      final UploadTask uploadTask = ref.putData(bytes, metadata);
      
      // Monitor upload progress with better error detection
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          debugPrint('📊 Upload progress: ${progress.toStringAsFixed(2)}% (${snapshot.bytesTransferred}/${snapshot.totalBytes} bytes)');
          debugPrint('   State: ${snapshot.state}');
        },
        onError: (error) {
          debugPrint('❌ Upload stream error: $error');
        },
      );
      
      // Wait for upload to complete with timeout
      debugPrint('⏳ Waiting for upload to complete...');
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('❌ Upload timeout after 30 seconds');
          throw Exception('Upload timed out. Please check your internet connection and Firebase Storage rules.');
        },
      );
      
      debugPrint('✅ Upload task completed. State: ${snapshot.state}');
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase error uploading image:');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      debugPrint('   Plugin: ${e.plugin}');
      throw Exception('Upload failed: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      debugPrint('   Error type: ${e.runtimeType}');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadMultipleProductImages(
    List<XFile> imageFiles,
    String productId,
  ) async {
    List<String> downloadUrls = [];
    
    for (var imageFile in imageFiles) {
      final String? url = await uploadProductImage(imageFile, productId);
      if (url != null) {
        downloadUrls.add(url);
      }
    }
    
    return downloadUrls;
  }

  /// Delete image from Firebase Storage
  Future<bool> deleteProductImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('✅ Image deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Delete multiple images
  Future<void> deleteMultipleProductImages(List<String> imageUrls) async {
    for (var url in imageUrls) {
      await deleteProductImage(url);
    }
  }
}
