import 'package:flutter/material.dart';
import 'package:shared_models/models/fixture_model.dart';
import 'package:work_app/services/fixtures_api.dart';

class PowerCalcPage extends StatefulWidget {
  const PowerCalcPage({super.key});

  @override
  State<PowerCalcPage> createState() => _PowerCalcPageState();
}

class _PowerCalcPageState extends State<PowerCalcPage> {
  late Future<List<Fixture>> _fixturesFuture;
  final Map<int, int> _quantities = {}; // fixtureId -> quantity

  @override
  void initState() {
    super.initState();
    _fixturesFuture = _loadFixtures();
  }

  Future<List<Fixture>> _loadFixtures() async {
    return await FixturesApi.getFixtures();
  }

  double get _totalAmps {
    double total = 0;
    _quantities.forEach((fixtureId, quantity) {
      final fixture = _fixtures.firstWhere((f) => f.id == fixtureId);
      total += (fixture.powerPeakAmps ?? 0) * quantity;
    });
    return total;
  }

  late List<Fixture> _fixtures;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Fixture>>(
        future: _fixturesFuture,
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

          _fixtures = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _fixtures.length,
                  itemBuilder: (context, index) {
                    final fixture = _fixtures[index];
                    final quantity = _quantities[fixture.id] ?? 0;
                    return ListTile(
                      title: Text(fixture.modelName),
                      subtitle: Text('Manufacturer: ${fixture.manufacturerId}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (quantity > 0) {
                                setState(() {
                                  _quantities[fixture.id] = quantity - 1;
                                });
                              }
                            },
                          ),
                          Text(quantity.toString()),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _quantities[fixture.id] = quantity + 1;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                //color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Peak Amps:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _totalAmps.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
