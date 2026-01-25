import 'package:flutter/material.dart';
import 'package:shared_models/models/fixture_model.dart';
import 'package:work_app/models/fixture_tabledata.dart';
import 'package:work_app/pages/fixture_detail_page.dart';
import 'package:work_app/services/fixtures_api.dart';
import 'package:work_app/widgets/fixture_datatable.dart';

class FixtureInfoPage extends StatefulWidget {
  const FixtureInfoPage({super.key});

  @override
  State<FixtureInfoPage> createState() => _FixtureInfoPageState();
}

class _FixtureInfoPageState extends State<FixtureInfoPage> {
  late Future<FixtureTableData> _dataFuture;

  Map<int, String> _manufacturerMap = {};
  Map<int, String> _typeMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dataFuture = _fetchData();
  }

  Future<FixtureTableData> _fetchData() async {
    final fixtures = await FixturesApi.getFixtures();
    final manufacturers = await FixturesApi.getManufacturers();
    final types = await FixturesApi.getFixtureTypes();

    _manufacturerMap = {for (final m in manufacturers) m.id: m.name};
    _typeMap = {for (final t in types) t.id: t.name};

    return FixtureTableData(
      fixtures: fixtures,
      manufacturerMap: _manufacturerMap,
      typeMap: _typeMap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFixtureDialog(null, _manufacturerMap, _typeMap),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<FixtureTableData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final data = snapshot.data!;
          return FixtureDataTable(
            fixtures: data.fixtures,
            manufacturerMap: data.manufacturerMap,
            typeMap: data.typeMap,
            onTap: (fixture) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FixtureDetailPage(
                    fixture: fixture,
                    manufacturerMap: data.manufacturerMap,
                    typeMap: data.typeMap,
                  ),
                ),
              );
              setState(_loadData);
            },
            onLongPress: (fixture) =>
                _showFixtureDialog(fixture, data.manufacturerMap, data.typeMap),
          );
        },
      ),
    );
  }

  void _showFixtureDialog(
    Fixture? fixture,
    Map<int, String> manufacturerMap,
    Map<int, String> typeMap,
  ) {
    final isNew = fixture == null;

    final modelController = TextEditingController(
      text: fixture?.modelName ?? '',
    );

    final newManufacturerController = TextEditingController();

    int? selectedTypeId = fixture?.fixtureTypeId;
    int? selectedManufacturerId = fixture?.manufacturerId;
    bool isNewManufacturer = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isNew ? 'New Fixture' : 'Edit Fixture'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Model name
                    TextField(
                      controller: modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model Name',
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Fixture type dropdown
                    DropdownButtonFormField<int>(
                      initialValue: selectedTypeId,
                      hint: const Text('Select fixture type'),
                      decoration: const InputDecoration(
                        labelText: 'Fixture Type',
                      ),
                      items: typeMap.entries
                          .map(
                            (e) => DropdownMenuItem<int>(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedTypeId = value);
                      },
                    ),

                    const SizedBox(height: 16),

                    /// Manufacturer dropdown
                    DropdownButtonFormField<int?>(
                      initialValue: isNewManufacturer
                          ? null
                          : selectedManufacturerId,
                      hint: const Text('Select Manufactuerer'),
                      decoration: const InputDecoration(
                        labelText: 'Manufacturer',
                      ),
                      items: [
                        ...manufacturerMap.entries.map(
                          (e) => DropdownMenuItem<int?>(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        ),
                        const DropdownMenuItem<int?>(
                          value: -1,
                          child: Text('➕ New manufacturer'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == -1) {
                            isNewManufacturer = true;
                            selectedManufacturerId = null;
                          } else {
                            isNewManufacturer = false;
                            selectedManufacturerId = value;
                          }
                        });
                      },
                    ),

                    /// New manufacturer input
                    if (isNewManufacturer) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: newManufacturerController,
                        decoration: const InputDecoration(
                          labelText: 'New Manufacturer Name',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (!isNew)
                  TextButton(
                    onPressed: () async {
                      await FixturesApi.deleteFixture(fixture.id);
                      Navigator.pop(context);
                      setState(_loadData);
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final modelName = modelController.text.trim();

                    if (modelName.isEmpty || selectedTypeId == null) return;

                    if (isNew) {
                      await FixturesApi.createFixture(
                        fixtureTypeId: selectedTypeId!,
                        modelName: modelName,
                        manufacturerId: isNewManufacturer
                            ? null
                            : selectedManufacturerId,
                        manufacturerName: isNewManufacturer
                            ? newManufacturerController.text
                            : null,
                      );
                    } else {
                      await FixturesApi.updateFixture(
                        fixture.id,
                        fixtureTypeId: selectedTypeId!,
                        modelName: modelName,
                        manufacturerId: isNewManufacturer
                            ? null
                            : selectedManufacturerId,
                        manufacturerName: isNewManufacturer
                            ? newManufacturerController.text
                            : null,
                      );
                    }

                    Navigator.pop(context);
                    setState(_loadData);
                  },
                  child: Text(isNew ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
