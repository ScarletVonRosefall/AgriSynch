import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';

class ReviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit a review for a farmer
  static Future<bool> submitReview({
    required String farmerId,
    required String farmerName,
    required double rating,
    String? comment,
    String? orderId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user');
        return false;
      }

      // Get buyer info
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final buyerName = userDoc.data()?['name'] ?? 'Anonymous Buyer';

      // Check if buyer has already reviewed this farmer
      final existingReview = await _firestore
          .collection('reviews')
          .where('farmerId', isEqualTo: farmerId)
          .where('buyerId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (existingReview.docs.isNotEmpty) {
        // Update existing review
        final reviewId = existingReview.docs.first.id;
        await _firestore.collection('reviews').doc(reviewId).update({
          'rating': rating,
          'comment': comment,
          'orderId': orderId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Review updated');
      } else {
        // Create new review
        final review = Review(
          id: '',
          farmerId: farmerId,
          farmerName: farmerName,
          buyerId: currentUser.uid,
          buyerName: buyerName,
          rating: rating,
          comment: comment,
          orderId: orderId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('reviews').add(review.toFirestore());
        print('✅ Review submitted');
      }

      // Update farmer's average rating
      await _updateFarmerRating(farmerId);

      return true;
    } catch (e) {
      print('❌ Error submitting review: $e');
      return false;
    }
  }

  /// Update farmer's average rating in users collection
  static Future<void> _updateFarmerRating(String farmerId) async {
    try {
      // Get all reviews for this farmer
      final reviews = await _firestore
          .collection('reviews')
          .where('farmerId', isEqualTo: farmerId)
          .get();

      if (reviews.docs.isEmpty) {
        // No reviews, set rating to null
        await _firestore.collection('users').doc(farmerId).update({
          'averageRating': null,
          'reviewCount': 0,
        });
        return;
      }

      // Calculate average rating
      double totalRating = 0;
      for (var doc in reviews.docs) {
        totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
      }
      final averageRating = totalRating / reviews.docs.length;
      final reviewCount = reviews.docs.length;

      // Update farmer's user document
      await _firestore.collection('users').doc(farmerId).update({
        'averageRating': averageRating,
        'reviewCount': reviewCount,
      });

      print('✅ Updated farmer rating: $averageRating ($reviewCount reviews)');
    } catch (e) {
      print('❌ Error updating farmer rating: $e');
    }
  }

  /// Get reviews for a specific farmer
  static Stream<List<Review>> getFarmerReviewsStream(String farmerId) {
    return _firestore
        .collection('reviews')
        .where('farmerId', isEqualTo: farmerId)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => Review.fromFirestore(doc))
          .toList();
      
      // Sort by date (newest first) - client-side to avoid index
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return reviews;
    });
  }

  /// Get farmer's rating statistics
  static Future<Map<String, dynamic>> getFarmerRatingStats(String farmerId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(farmerId).get();
      final data = userDoc.data();

      return {
        'averageRating': data?['averageRating'] ?? 0.0,
        'reviewCount': data?['reviewCount'] ?? 0,
      };
    } catch (e) {
      print('❌ Error getting farmer rating stats: $e');
      return {
        'averageRating': 0.0,
        'reviewCount': 0,
      };
    }
  }

  /// Check if current user has reviewed a farmer
  static Future<Review?> getCurrentUserReview(String farmerId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final snapshot = await _firestore
          .collection('reviews')
          .where('farmerId', isEqualTo: farmerId)
          .where('buyerId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Review.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('❌ Error getting current user review: $e');
      return null;
    }
  }

  /// Delete a review (only by the reviewer)
  static Future<bool> deleteReview(String reviewId, String farmerId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Verify ownership
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists || reviewDoc.data()?['buyerId'] != currentUser.uid) {
        print('❌ Unauthorized to delete review');
        return false;
      }

      await _firestore.collection('reviews').doc(reviewId).delete();
      
      // Update farmer's average rating
      await _updateFarmerRating(farmerId);

      print('✅ Review deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting review: $e');
      return false;
    }
  }

  /// Get top-rated farmers
  static Future<List<Map<String, dynamic>>> getTopRatedFarmers({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('accountType', isEqualTo: 'Farmer')
          .where('averageRating', isGreaterThan: 0)
          .get();

      // Sort by rating client-side
      final farmers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'location': data['location'] ?? '',
          'averageRating': data['averageRating'] ?? 0.0,
          'reviewCount': data['reviewCount'] ?? 0,
        };
      }).toList();

      farmers.sort((a, b) {
        final ratingCompare = (b['averageRating'] as double).compareTo(a['averageRating'] as double);
        if (ratingCompare != 0) return ratingCompare;
        // If ratings are equal, sort by review count
        return (b['reviewCount'] as int).compareTo(a['reviewCount'] as int);
      });

      return farmers.take(limit).toList();
    } catch (e) {
      print('❌ Error getting top-rated farmers: $e');
      return [];
    }
  }
}
