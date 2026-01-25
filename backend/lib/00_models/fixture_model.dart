// class FixtureModel {
//   final int id;
//   final int manufacturerId;
//   final int fixtureTypeId;

//   final String modelName;

//   final String shortName;
//   final double? powerPeakAmps;
//   final String usualDmxMode;
//   final String notes;

//   final DateTime createdAt;
//   final DateTime updatedAt;

//   FixtureModel({
//     required this.id,
//     required this.manufacturerId,
//     required this.fixtureTypeId,
//     required this.modelName,
//     this.shortName = '',
//     this.powerPeakAmps,
//     this.usualDmxMode = '',
//     this.notes = '',
//     required this.createdAt,
//     required this.updatedAt,
//   });

//   factory FixtureModel.fromMap(Map<String, dynamic> map) {
//     return FixtureModel(
//       id: map['id'],
//       manufacturerId: map['manufacturer_id'],
//       fixtureTypeId: map['fixture_type_id'],
//       modelName: map['model_name'],
//       shortName: map['short_name'],
//       powerPeakAmps: map['power_peak_amps'] != null
//           ? double.parse(map['power_peak_amps'])
//           : null,
//       usualDmxMode: map['usual_dmx_mode'],
//       notes: map['notes'],
//       createdAt: map['created_at'],
//       updatedAt: map['updated_at'],
//     );
//   }

//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'manufacturer_id': manufacturerId,
//     'fixture_type_id': fixtureTypeId,
//     'model_name': modelName,
//     'short_name': shortName,
//     'power_peak_amps': powerPeakAmps,
//     'usual_dmx_mode': usualDmxMode,
//     'notes': notes,
//     'created_at': createdAt.toIso8601String(),
//     'updated_at': updatedAt.toIso8601String(),
//   };
// }

// class Manufacturer {
//   final int id;
//   final String name;

//   Manufacturer({required this.id, required this.name});

//   factory Manufacturer.fromMap(Map<String, dynamic> map) {
//     return Manufacturer(id: map['id'], name: map['name']);
//   }

//   Map<String, dynamic> toJson() => {'id': id, 'name': name};
// }

// class FixtureType {
//   final int id;
//   final String name;

//   FixtureType({required this.id, required this.name});

//   factory FixtureType.fromMap(Map<String, dynamic> map) {
//     return FixtureType(id: map['id'], name: map['name']);
//   }

//   Map<String, dynamic> toJson() => {'id': id, 'name': name};
// }
