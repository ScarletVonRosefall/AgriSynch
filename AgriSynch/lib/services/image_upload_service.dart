import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

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
      print('Error picking image: $e');
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
      print('Error taking photo: $e');
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
      print('Error picking multiple images: $e');
      return [];
    }
  }

  /// Upload image to Firebase Storage
  Future<String?> uploadProductImage(XFile imageFile, String productId) async {
    if (currentUserId == null) {
      print('Error: User not authenticated');
      return null;
    }

    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final String filePath = 'products/$currentUserId/$productId/$fileName';
      
      final File file = File(imageFile.path);
      final Reference ref = _storage.ref().child(filePath);
      
      // Upload file
      final UploadTask uploadTask = ref.putFile(file);
      
      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
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
      print('✅ Image deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
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
