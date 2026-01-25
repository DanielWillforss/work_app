import 'package:flutter/material.dart';
import 'package:shared_models/models/timelog_model.dart';
import 'package:work_app/services/timelog_api.dart';
import 'package:work_app/util.dart';

class LogHoursPage extends StatefulWidget {
  const LogHoursPage({super.key});

  @override
  State<LogHoursPage> createState() => _LogHoursPage();
}

class _LogHoursPage extends State<LogHoursPage> {
  late Future<List<Timelog>> _timelogsFuture;

  @override
  void initState() {
    super.initState();
    _loadTimelogs();
  }

  void _loadTimelogs() {
    _timelogsFuture = TimelogsApi.getTimelogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _showDialogWindow(null);
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.cloud_upload),
          label: const Text('Upload Timelogs'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50), // full-width button
          ),
          onPressed: () async {
            await TimelogsApi.uploadTimelogs();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Timelogs uploaded')));
          },
        ),
      ),

      body: FutureBuilder<List<Timelog>>(
        future: _timelogsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final timelogs = snapshot.data!;
          if (timelogs.isEmpty) {
            return const Center(child: Text('No timelogs yet'));
          }

          return ListView.builder(
            itemCount: timelogs.length,
            itemBuilder: (context, index) {
              final log = timelogs[index];
              return ListTile(
                title: Text(log.note ?? '(no content)'),
                subtitle: Text(
                  '${log.startTimeAsString()} → ${log.endTimeAsString() ?? '-'}',
                ),
                onLongPress: () async {
                  await _showDialogWindow(log);
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showDialogWindow(Timelog? log) async {
    final bool isNewLog = log == null;
    final contentController = TextEditingController(text: log?.note ?? '');
    DateTime startTime = isNewLog ? DateTime.now() : log.startTime;
    DateTime? endTime = isNewLog ? null : log.endTime;

    Future<void> pickDateTime(bool isStartTime) async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: isStartTime ? startTime : endTime ?? startTime,
        firstDate: isStartTime ? DateTime(2000) : startTime,
        lastDate: DateTime(2100),
      );
      if (pickedDate != null) {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: isStartTime
              ? TimeOfDay.fromDateTime(startTime)
              : endTime != null
              ? TimeOfDay.fromDateTime(endTime!)
              : TimeOfDay.now(),
        );
        if (pickedTime != null) {
          setState(() {
            if (isStartTime) {
              startTime = dateTimeFromDatePicker(pickedDate, pickedTime);
            } else {
              endTime = dateTimeFromDatePicker(pickedDate, pickedTime);
            }
          });
        }
      }
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isNewLog ? 'New Timelog' : 'Edit Timelog'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Start: ${startTime.toLocal()}'.split('.').first,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await pickDateTime(true);
                      setState(() {});
                    },
                    child: const Text('Pick Start'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'End: ${endTime != null ? endTime!.toLocal().toString().split('.').first : "Not set"}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await pickDateTime(false);
                      setState(() {});
                    },
                    child: const Text('Pick End'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                isNewLog
                    ? await TimelogsApi.createTimelog(
                        note: contentController.text,
                        startTime: startTime,
                        endTime: endTime,
                      )
                    : await TimelogsApi.updateTimelog(
                        log.id,
                        note: contentController.text,
                        startTime: startTime,
                        endTime: endTime,
                      );
                Navigator.pop(context);
                setState(_loadTimelogs);
              },
              child: Text(isNewLog ? 'Save' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
