class AgriculturalData {
  final String? cropType;
  final String? fieldLocation;
  final String? weatherDependency;
  final double? expectedYield;
  final String? soilCondition;
  final Map<String, dynamic>? irrigation;

  AgriculturalData({
    this.cropType,
    this.fieldLocation,
    this.weatherDependency,
    this.expectedYield,
    this.soilCondition,
    this.irrigation,
  });

  factory AgriculturalData.fromMap(Map<String, dynamic> map) {
    return AgriculturalData(
      cropType: map['cropType'],
      fieldLocation: map['fieldLocation'],
      weatherDependency: map['weatherDependency'],
      expectedYield: map['expectedYield']?.toDouble(),
      soilCondition: map['soilCondition'],
      irrigation: map['irrigation'],
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
    };
  }

  AgriculturalData copyWith({
    String? cropType,
    String? fieldLocation,
    String? weatherDependency,
    double? expectedYield,
    String? soilCondition,
    Map<String, dynamic>? irrigation,
  }) {
    return AgriculturalData(
      cropType: cropType ?? this.cropType,
      fieldLocation: fieldLocation ?? this.fieldLocation,
      weatherDependency: weatherDependency ?? this.weatherDependency,
      expectedYield: expectedYield ?? this.expectedYield,
      soilCondition: soilCondition ?? this.soilCondition,
      irrigation: irrigation ?? this.irrigation,
    );
  }
}