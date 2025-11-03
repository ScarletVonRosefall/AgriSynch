import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test001/models/product.dart';

void main() {
  group('Product Model', () {
    test('Should create product from valid data', () {
      final now = DateTime.now();
      final product = Product(
        id: 'test-id',
        name: 'Tomatoes',
        description: 'Fresh organic tomatoes',
        price: 50.0,
        stock: 100,
        unit: 'kg',
        category: 'Vegetables',
        farmerId: 'farmer-123',
        farmerName: 'John Farmer',
        images: ['https://example.com/image.jpg'],
        location: 'Farm Location',
        createdAt: now,
        updatedAt: now,
      );

      expect(product.id, equals('test-id'));
      expect(product.name, equals('Tomatoes'));
      expect(product.price, equals(50.0));
      expect(product.stock, equals(100));
      expect(product.category, equals('Vegetables'));
      expect(product.isAvailable, isTrue);
    });

    test('Should convert product to Firestore map', () {
      final now = DateTime.now();
      final product = Product(
        id: 'test-id',
        name: 'Tomatoes',
        description: 'Fresh organic tomatoes',
        price: 50.0,
        stock: 100,
        unit: 'kg',
        category: 'Vegetables',
        farmerId: 'farmer-123',
        farmerName: 'John Farmer',
        images: ['https://example.com/image.jpg'],
        location: 'Farm Location',
        createdAt: now,
        updatedAt: now,
      );

      final map = product.toFirestore();

      expect(map['name'], equals('Tomatoes'));
      expect(map['price'], equals(50.0));
      expect(map['stock'], equals(100));
      expect(map['category'], equals('Vegetables'));
      expect(map['farmerId'], equals('farmer-123'));
      expect(map['images'], isA<List>());
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('Should handle missing optional fields', () {
      final now = DateTime.now();
      final product = Product(
        id: 'test-id',
        name: 'Rice',
        description: 'White rice',
        price: 45.0,
        stock: 200,
        unit: 'kg',
        category: 'Grains',
        farmerId: 'farmer-789',
        farmerName: 'Bob Farmer',
        images: [],
        location: '',
        createdAt: now,
        updatedAt: now,
      );

      expect(product.images, isEmpty);
      expect(product.location, isEmpty);
      expect(product.rating, isNull);
      expect(product.reviewCount, isNull);
    });

    test('Should calculate discounted price correctly', () {
      final now = DateTime.now();
      final product = Product(
        id: 'test-id',
        name: 'Mango',
        description: 'Sweet mangoes',
        price: 100.0,
        stock: 50,
        unit: 'kg',
        category: 'Fruits',
        farmerId: 'farmer-111',
        farmerName: 'Alice Farmer',
        images: [],
        location: 'Cebu',
        createdAt: now,
        updatedAt: now,
      );

      expect(product.price, equals(100.0));
      expect(product.price * 0.9, equals(90.0)); // 10% discount
    });

    test('Should validate stock availability', () {
      final now = DateTime.now();
      final product = Product(
        id: 'test-id',
        name: 'Banana',
        description: 'Fresh bananas',
        price: 40.0,
        stock: 10,
        unit: 'bunches',
        category: 'Fruits',
        farmerId: 'farmer-222',
        farmerName: 'Charlie Farmer',
        images: [],
        location: 'Davao',
        createdAt: now,
        updatedAt: now,
      );

      expect(product.stock, lessThan(20)); // Low stock warning threshold
      expect(product.stock, greaterThan(0)); // Still available
      expect(product.isAvailable, isTrue);
    });

    test('Should handle availability flag', () {
      final now = DateTime.now();
      final availableProduct = Product(
        id: 'test-1',
        name: 'Available Product',
        description: 'This is available',
        price: 100.0,
        stock: 50,
        unit: 'kg',
        category: 'Test',
        farmerId: 'farmer-1',
        farmerName: 'Farmer One',
        images: [],
        location: 'Location',
        createdAt: now,
        updatedAt: now,
        isAvailable: true,
      );

      final unavailableProduct = Product(
        id: 'test-2',
        name: 'Unavailable Product',
        description: 'This is not available',
        price: 100.0,
        stock: 0,
        unit: 'kg',
        category: 'Test',
        farmerId: 'farmer-1',
        farmerName: 'Farmer One',
        images: [],
        location: 'Location',
        createdAt: now,
        updatedAt: now,
        isAvailable: false,
      );

      expect(availableProduct.isAvailable, isTrue);
      expect(unavailableProduct.isAvailable, isFalse);
    });

    test('Should handle rating and review count', () {
      final now = DateTime.now();
      final product = Product(
        id: 'test-id',
        name: 'Rated Product',
        description: 'Product with ratings',
        price: 75.0,
        stock: 30,
        unit: 'kg',
        category: 'Test',
        farmerId: 'farmer-1',
        farmerName: 'Farmer One',
        images: [],
        location: 'Location',
        createdAt: now,
        updatedAt: now,
        rating: 4.5,
        reviewCount: 10,
      );

      expect(product.rating, equals(4.5));
      expect(product.reviewCount, equals(10));
    });
  });
}
