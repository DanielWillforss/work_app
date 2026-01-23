class Fixture {
  final int id;
  final int manufacturerId;
  final int fixtureTypeId;

  final String modelName;

  final String shortName;
  final double? powerPeakAmps;
  final String usualDmxMode;
  final String notes;

  Fixture({
    required this.id,
    required this.manufacturerId,
    required this.fixtureTypeId,
    required this.modelName,
    this.shortName = '',
    this.powerPeakAmps,
    this.usualDmxMode = '',
    this.notes = '',
  });

  factory Fixture.fromJson(Map<String, dynamic> json) {
    return Fixture(
      id: json['id'],
      manufacturerId: json['manufacturer_id'],
      fixtureTypeId: json['fixture_type_id'],
      modelName: json['model_name'],
      shortName: json['short_name'],
      powerPeakAmps: json['power_peak_amps'] != null
          ? (json['power_peak_amps'] as num).toDouble()
          : null,
      usualDmxMode: json['usual_dmx_mode'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'manufacturer_id': manufacturerId,
    'fixture_type_id': fixtureTypeId,
    'model_name': modelName,
    'short_name': shortName,
    'power_peak_amps': powerPeakAmps,
    'usual_dmx_mode': usualDmxMode,
    'notes': notes,
  };
}

class Manufacturer {
  final int id;
  final String name;

  Manufacturer({required this.id, required this.name});

  factory Manufacturer.fromMap(Map<String, dynamic> map) {
    return Manufacturer(id: map['id'], name: map['name']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class FixtureType {
  final int id;
  final String name;

  FixtureType({required this.id, required this.name});

  factory FixtureType.fromMap(Map<String, dynamic> map) {
    return FixtureType(id: map['id'], name: map['name']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
