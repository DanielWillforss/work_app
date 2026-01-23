import 'dart:async';
import 'package:flutter/material.dart';
import 'package:work_app/models/fixture.dart';
import 'package:work_app/services/fixtures_api.dart';

class FixtureDetailPage extends StatefulWidget {
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
  State<FixtureDetailPage> createState() => _FixtureDetailPageState();
}

class _FixtureDetailPageState extends State<FixtureDetailPage> {
  late TextEditingController _shortNameController;
  late TextEditingController _powerPeakController;
  late TextEditingController _dmxModeController;
  late TextEditingController _notesController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _shortNameController = TextEditingController(
      text: widget.fixture.shortName,
    );
    _powerPeakController = TextEditingController(
      text: widget.fixture.powerPeakAmps?.toStringAsFixed(2) ?? '',
    );
    _dmxModeController = TextEditingController(
      text: widget.fixture.usualDmxMode,
    );
    _notesController = TextEditingController(text: widget.fixture.notes);

    // Add listeners for real-time updates
    _shortNameController.addListener(_onChange);
    _powerPeakController.addListener(_onChange);
    _dmxModeController.addListener(_onChange);
    _notesController.addListener(_onChange);
  }

  void _onChange() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _updateFixture);
  }

  Future<void> _updateFixture() async {
    try {
      final powerPeak = double.tryParse(_powerPeakController.text);
      await FixturesApi.updateFixture(
        widget.fixture.id,
        manufacturerId: widget.fixture.manufacturerId,
        fixtureTypeId: widget.fixture.fixtureTypeId,
        modelName: widget.fixture.modelName,
        shortName: _shortNameController.text,
        powerPeakAmps: powerPeak,
        usualDmxMode: _dmxModeController.text,
        notes: _notesController.text,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update fixture')));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _shortNameController.dispose();
    _powerPeakController.dispose();
    _dmxModeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fixture.modelName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailRow(label: 'Model Name', value: widget.fixture.modelName),
          EditableRow(label: 'Short Name', controller: _shortNameController),
          DetailRow(
            label: 'Manufacturer',
            value:
                widget.manufacturerMap[widget.fixture.manufacturerId] ??
                'Unknown',
          ),
          DetailRow(
            label: 'Type',
            value: widget.typeMap[widget.fixture.fixtureTypeId] ?? 'Unknown',
          ),
          EditableRow(
            label: 'Power Peak (Amps)',
            controller: _powerPeakController,
          ),
          EditableRow(label: 'Usual DMX Mode', controller: _dmxModeController),
          EditableRow(
            label: 'Notes',
            controller: _notesController,
            maxLines: 5,
          ),
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

class EditableRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;

  const EditableRow({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

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
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
