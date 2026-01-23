import 'package:intl/intl.dart';

class Timelog {
  final int id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? note;

  Timelog({required this.id, required this.startTime, this.endTime, this.note});

  factory Timelog.fromJson(Map<String, dynamic> json) {
    return Timelog(
      id: json['id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : null,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'note': note,
    };
  }

  String startTimeAsString() {
    return DateFormat('d/M HH:mm').format(startTime);
  }

  String? endTimeAsString() {
    if (endTime == null) {
      return null;
    }
    return DateFormat('d/M HH:mm').format(endTime!);
  }
}
