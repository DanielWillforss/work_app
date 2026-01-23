import 'package:flutter/material.dart';
import 'package:work_app/models/fixture.dart';

class FixtureDataTable extends StatelessWidget {
  final List<Fixture> fixtures;
  final Map<int, String> manufacturerMap;
  final Map<int, String> typeMap;
  final void Function(Fixture fixture) onTap;
  final void Function(Fixture fixture) onLongPress;

  const FixtureDataTable({
    super.key,
    required this.fixtures,
    required this.manufacturerMap,
    required this.typeMap,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('Model')),
            DataColumn(label: Text('Short Name')),
            DataColumn(label: Text('Manufacturer')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Peak Amps')),
            DataColumn(label: Text('DMX Mode')),
            DataColumn(label: Text('Notes')),
          ],
          rows: fixtures.map((fixture) {
            return DataRow(
              cells: [
                DataCell(Text(fixture.modelName)),
                DataCell(Text(fixture.shortName)),
                DataCell(
                  Text(manufacturerMap[fixture.manufacturerId] ?? 'Unknown'),
                ),
                DataCell(Text(typeMap[fixture.fixtureTypeId] ?? 'Unknown')),
                DataCell(Text(fixture.powerPeakAmps?.toStringAsFixed(2) ?? '')),
                DataCell(Text(fixture.usualDmxMode)),
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(fixture.notes, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onSelectChanged: (_) => onTap(fixture),
              onLongPress: () => onLongPress(fixture),
            );
          }).toList(),
        ),
      ),
    );
  }
}
