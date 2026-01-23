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
}
