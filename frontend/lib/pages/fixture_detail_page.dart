import 'package:flutter/material.dart';
import 'package:work_app/models/fixture.dart';

class FixtureDetailPage extends StatelessWidget {
  final Fixture fixture;
  final Map<int, String> manufacturerMap;
  final Map<int, String> typeMap;

  const FixtureDetailPage({
    super.key,
    required this.fixture,
    required this.manufacturerMap,
    required this.typeMap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fixture.modelName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailRow(label: 'Model Name', value: fixture.modelName),
          DetailRow(label: 'Short Name', value: fixture.shortName),
          DetailRow(
            label: 'Manufacturer',
            value: manufacturerMap[fixture.manufacturerId] ?? 'Unknown',
          ),
          DetailRow(
            label: 'Type',
            value: typeMap[fixture.fixtureTypeId] ?? 'Unknown',
          ),
          DetailRow(
            label: 'Power Peak (Amps)',
            value: fixture.powerPeakAmps?.toStringAsFixed(2) ?? '',
          ),
          DetailRow(label: 'Usual DMX Mode', value: fixture.usualDmxMode),
          DetailRow(label: 'Notes', value: fixture.notes),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
