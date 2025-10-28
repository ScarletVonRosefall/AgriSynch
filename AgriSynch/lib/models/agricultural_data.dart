import 'package:cloud_firestore/cloud_firestore.dart';

class AgriculturalData {
  final String? cropType;
  final String? fieldLocation;
  final String? weatherDependency;
  final double? expectedYield;
  final String? soilCondition;
  final Map<String, dynamic>? irrigation;
  final DateTime? plantingDate;
  final String? growthStage;
  final List<Map<String, dynamic>>? fertilizerSchedule;
  final List<Map<String, dynamic>>? pestControlHistory;
  final Map<String, dynamic>? cropMetrics; // For additional crop-specific measurements

  AgriculturalData({
    this.cropType,
    this.fieldLocation,
    this.weatherDependency,
    this.expectedYield,
    this.soilCondition,
    this.irrigation,
    this.plantingDate,
    this.growthStage,
    this.fertilizerSchedule,
    this.pestControlHistory,
    this.cropMetrics,
  });

  factory AgriculturalData.fromMap(Map<String, dynamic> map) {
    return AgriculturalData(
      cropType: map['cropType'],
      fieldLocation: map['fieldLocation'],
      weatherDependency: map['weatherDependency'],
      expectedYield: map['expectedYield']?.toDouble(),
      soilCondition: map['soilCondition'],
      irrigation: map['irrigation'],
      plantingDate: map['plantingDate'] != null ? 
          (map['plantingDate'] as Timestamp).toDate() : null,
      growthStage: map['growthStage'],
      fertilizerSchedule: List<Map<String, dynamic>>.from(map['fertilizerSchedule'] ?? []),
      pestControlHistory: List<Map<String, dynamic>>.from(map['pestControlHistory'] ?? []),
      cropMetrics: map['cropMetrics'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropType': cropType,
      'fieldLocation': fieldLocation,
      'weatherDependency': weatherDependency,
      'expectedYield': expectedYield,
      'soilCondition': soilCondition,
      'irrigation': irrigation,
      'plantingDate': plantingDate != null ? Timestamp.fromDate(plantingDate!) : null,
      'growthStage': growthStage,
      'fertilizerSchedule': fertilizerSchedule ?? [],
      'pestControlHistory': pestControlHistory ?? [],
      'cropMetrics': cropMetrics,
    };
  }

  AgriculturalData copyWith({
    String? cropType,
    String? fieldLocation,
    String? weatherDependency,
    double? expectedYield,
    String? soilCondition,
    Map<String, dynamic>? irrigation,
    DateTime? plantingDate,
    String? growthStage,
    List<Map<String, dynamic>>? fertilizerSchedule,
    List<Map<String, dynamic>>? pestControlHistory,
    Map<String, dynamic>? cropMetrics,
  }) {
    return AgriculturalData(
      cropType: cropType ?? this.cropType,
      fieldLocation: fieldLocation ?? this.fieldLocation,
      weatherDependency: weatherDependency ?? this.weatherDependency,
      expectedYield: expectedYield ?? this.expectedYield,
      soilCondition: soilCondition ?? this.soilCondition,
      irrigation: irrigation ?? this.irrigation,
      plantingDate: plantingDate ?? this.plantingDate,
      growthStage: growthStage ?? this.growthStage,
      fertilizerSchedule: fertilizerSchedule ?? this.fertilizerSchedule,
      pestControlHistory: pestControlHistory ?? this.pestControlHistory,
      cropMetrics: cropMetrics ?? this.cropMetrics,
    );
  }
}