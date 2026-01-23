import 'package:work_app/models/fixture.dart';

class FixtureTableData {
  final List<Fixture> fixtures;
  final Map<int, String> manufacturerMap;
  final Map<int, String> typeMap;

  FixtureTableData({
    required this.fixtures,
    required this.manufacturerMap,
    required this.typeMap,
  });
}
