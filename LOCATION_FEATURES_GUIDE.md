# Location Data Guide: Using GPS Coordinates Throughout AgriSynch

## Overview

The new comprehensive signup captures GPS coordinates (latitude/longitude) for every user. This enables powerful location-based features.

## Data Available

For each user, you now have:

```dart
// From Firestore /users/{uid}
double latitude;      // e.g., 12.8797°
double longitude;     // e.g., 121.7740°
String location;      // e.g., "12.8797, 121.7740" (for display)
```

## How to Access Location Data

### From Firestore
```dart
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

final latitude = userDoc['latitude'] as double;
final longitude = userDoc['longitude'] as double;
```

### From Local Storage
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();
final latitude = double.parse(await storage.read(key: 'latitude') ?? '0');
final longitude = double.parse(await storage.read(key: 'longitude') ?? '0');
```

## Practical Use Cases

### 1. Calculate Distance Between Users

**Purpose:** Find nearest farmers/buyers

```dart
import 'dart:math' as math;

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const p = 0.017453292519943295; // Math.PI / 180
  final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) * math.cos(lat2 * p) *
          (1 - math.cos((lon2 - lon1) * p)) / 2;
  return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
}

// Usage: Find distance in kilometers
final distanceKm = calculateDistance(
  currentUser.latitude,
  currentUser.longitude,
  targetUser.latitude,
  targetUser.longitude,
);
```

### 2. Find Nearby Users

**Purpose:** Show local farmers/buyers

```dart
Future<List<UserData>> findNearbyUsers(
  double userLat,
  double userLon,
  double radiusKm,
) async {
  // Query users within approximate bounds
  final latChange = radiusKm / 111.0; // 1 degree lat ≈ 111 km
  final lonChange = radiusKm / (111.0 * math.cos(userLat * math.pi / 180));

  final minLat = userLat - latChange;
  final maxLat = userLat + latChange;
  final minLon = userLon - lonChange;
  final maxLon = userLon + lonChange;

  // Query Firestore
  final query = FirebaseFirestore.instance
      .collection('users')
      .where('latitude', isGreaterThan: minLat)
      .where('latitude', isLessThan: maxLat)
      .where('longitude', isGreaterThan: minLon)
      .where('longitude', isLessThan: maxLon);

  final snapshot = await query.get();
  
  // Filter by exact distance
  final results = <UserData>[];
  for (var doc in snapshot.docs) {
    final distance = calculateDistance(
      userLat,
      userLon,
      doc['latitude'],
      doc['longitude'],
    );
    
    if (distance <= radiusKm) {
      results.add(UserData.fromMap(doc.data()));
    }
  }
  
  return results;
}
```

### 3. Display Location on Map

**Purpose:** Show user/farm locations visually

```dart
// Add to pubspec.yaml:
// google_maps_flutter: ^2.5.0

import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String userName;

  const LocationMapView({
    required this.latitude,
    required this.longitude,
    required this.userName,
  });

  @override
  State<LocationMapView> createState() => _LocationMapViewState();
}

class _LocationMapViewState extends State<LocationMapView> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (controller) => mapController = controller,
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.latitude, widget.longitude),
        zoom: 15,
      ),
      markers: {
        Marker(
          markerId: MarkerId(widget.userName),
          position: LatLng(widget.latitude, widget.longitude),
          infoWindow: InfoWindow(title: widget.userName),
        ),
      },
    );
  }
}
```

### 4. Delivery Zone Calculation

**Purpose:** Determine if delivery is possible

```dart
bool isDeliveryAvailable(
  double farmLat,
  double farmLon,
  double buyerLat,
  double buyerLon,
  double maxDeliveryRadiusKm,
) {
  final distance = calculateDistance(
    farmLat,
    farmLon,
    buyerLat,
    buyerLon,
  );
  
  return distance <= maxDeliveryRadiusKm;
}

// Usage in order creation
if (isDeliveryAvailable(
  farmerLocation.latitude,
  farmerLocation.longitude,
  buyerLocation.latitude,
  buyerLocation.longitude,
  maxDeliveryRadiusKm: 15.0, // 15km radius
)) {
  // Allow order
} else {
  // Show error: "Delivery unavailable for this area"
}
```

### 5. Regional Analytics

**Purpose:** Analyze performance by region

```dart
Future<RegionalStats> getRegionalStats(double lat, double lon, double radiusKm) async {
  final nearbyFarmers = await findNearbyUsers(lat, lon, radiusKm)
      .then((users) => users.where((u) => u.accountType == 'Farmer').length);
  
  final nearbyBuyers = await findNearbyUsers(lat, lon, radiusKm)
      .then((users) => users.where((u) => u.accountType == 'Buyer').length);
  
  // Get transactions for this region
  final transactions = await FirebaseFirestore.instance
      .collection('transactions')
      .where('location', isGreaterThan: GeoPoint(lat - radiusKm/111, lon))
      .where('location', isLessThan: GeoPoint(lat + radiusKm/111, lon))
      .get();
  
  return RegionalStats(
    farmersCount: nearbyFarmers,
    buyersCount: nearbyBuyers,
    totalTransactions: transactions.docs.length,
  );
}
```

### 6. Location-Based Notifications

**Purpose:** Notify nearby users of new listings

```dart
Future<void> notifyNearbyUsers(
  double farmerLat,
  double farmerLon,
  String productName,
  double notificationRadiusKm,
) async {
  final nearbyUsers = await findNearbyUsers(
    farmerLat,
    farmerLon,
    notificationRadiusKm,
  );
  
  // Filter to buyers only
  final buyers = nearbyUsers.where((u) => u.accountType == 'Buyer');
  
  for (var buyer in buyers) {
    // Send notification
    await sendNotification(
      userId: buyer.uid,
      title: 'New Product Available Nearby!',
      body: '$productName from ${buyer.distanceAway.toStringAsFixed(1)}km away',
      data: {
        'farmerId': farmerLat.toString(),
        'product': productName,
      },
    );
  }
}
```

### 7. Sort Search Results by Distance

**Purpose:** Show closest items first

```dart
Future<List<FarmerProfile>> searchFarmersNearMe(
  String productType,
  double myLat,
  double myLon,
) async {
  // Get all farmers offering the product
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('accountType', isEqualTo: 'Farmer')
      .where('productsOffered', arrayContains: productType)
      .get();
  
  // Calculate distances
  final farmersWithDistance = <FarmerProfile>[];
  for (var doc in snapshot.docs) {
    final distance = calculateDistance(
      myLat,
      myLon,
      doc['latitude'],
      doc['longitude'],
    );
    
    farmersWithDistance.add(
      FarmerProfile.fromMap(doc.data(), distance: distance),
    );
  }
  
  // Sort by distance (nearest first)
  farmersWithDistance.sort((a, b) => a.distance.compareTo(b.distance));
  
  return farmersWithDistance;
}
```

## Adding Indexed Queries for Performance

For larger datasets, add composite indexes to Firestore:

```yaml
# In firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "accountType", "order": "ASCENDING" },
        { "fieldPath": "latitude", "order": "ASCENDING" },
        { "fieldPath": "longitude", "order": "ASCENDING" }
      ]
    }
  ]
}
```

## Example: Complete Farmer Discovery Feature

```dart
class FarmerDiscoveryPage extends StatefulWidget {
  @override
  State<FarmerDiscoveryPage> createState() => _FarmerDiscoveryPageState();
}

class _FarmerDiscoveryPageState extends State<FarmerDiscoveryPage> {
  late double _myLat, _myLon;
  List<FarmerProfile> _nearbyFarmers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyFarmers();
  }

  Future<void> _loadNearbyFarmers() async {
    final storage = FlutterSecureStorage();
    
    _myLat = double.parse(await storage.read(key: 'latitude') ?? '0');
    _myLon = double.parse(await storage.read(key: 'longitude') ?? '0');

    _nearbyFarmers = await searchFarmersNearMe('Poultry', _myLat, _myLon);
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Farmers Near Me')),
      body: ListView.builder(
        itemCount: _nearbyFarmers.length,
        itemBuilder: (context, index) {
          final farmer = _nearbyFarmers[index];
          return ListTile(
            title: Text(farmer.name),
            subtitle: Text('${farmer.distance.toStringAsFixed(1)} km away'),
            leading: const Icon(Icons.location_on),
            onTap: () {
              // Navigate to farmer profile
            },
          );
        },
      ),
    );
  }
}
```

## Firestore Rules for Location Queries

Update `firestore.rules` to allow location-based queries:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow update: if request.auth.uid == userId;
      allow create: if request.auth != null && 
                       request.auth.uid == userId &&
                       request.resource.data.keys().hasAll(['email', 'latitude', 'longitude']);
    }
  }
}
```

## Best Practices

1. **Cache Location Data:** Store user's location in local storage to avoid repeated Firestore reads
2. **Use Bounds First:** Use lat/lon bounds to filter before calculating exact distances
3. **Pagination:** For large datasets, implement pagination to avoid timeouts
4. **Update on Change:** When user moves significantly, update location
5. **Precision:** Store coordinates with 4+ decimal places (≈10 meters accuracy)
6. **Privacy:** Only show location to relevant users (neighbors, transaction partners)

## Testing Location Features

```dart
// Test with mock locations
const mockFarmerLat = 14.0995;
const mockFarmerLon = 121.5188;
const mockBuyerLat = 14.1000;
const mockBuyerLon = 121.5200;

final testDistance = calculateDistance(
  mockFarmerLat,
  mockFarmerLon,
  mockBuyerLat,
  mockBuyerLon,
);
expect(testDistance, lessThan(5)); // Should be ~0.2 km
```

## Summary

With GPS coordinates from signup, you can now:
- ✅ Find nearest users
- ✅ Calculate delivery zones
- ✅ Show location maps
- ✅ Regional analytics
- ✅ Location-based notifications
- ✅ Smart search sorting

All without asking users to enter their location manually!
