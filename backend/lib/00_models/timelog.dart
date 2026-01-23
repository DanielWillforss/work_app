import 'package:intl/intl.dart';

class Timelog {
  final int id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? note;

  Timelog({required this.id, required this.startTime, this.endTime, this.note});

  factory Timelog.fromMap(Map<String, dynamic> map) {
    return Timelog(
      id: map['id'] as int,
      startTime: map['start_time'] as DateTime,
      endTime: map['end_time'] as DateTime?,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'note': note,
    };
  }

  List<String> toSheetEntry() {
    final weekdaySv = DateFormat('EEEE', 'sv_SE').format(startTime);
    final date = '${startTime.day}/${startTime.month}';
    final start =
        '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';

    String end = '';
    String duration = '';

    if (endTime != null) {
      end = '${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}';

      final diff = endTime!.difference(startTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;

      duration = '${hours}h${minutes}min';
    }

    return [weekdaySv, date, start, end, duration, '', note ?? ''];
  }
}
