class ScheduleSlot {
  final String id;
  final String dayIndex;
  final String slotIndex;
  final String classId;
  final String teacherId;
  final String weekKey;

  ScheduleSlot({
    required this.id,
    required this.dayIndex,
    required this.slotIndex,
    required this.classId,
    required this.teacherId,
    required this.weekKey,
  });

  factory ScheduleSlot.fromMap(String id, Map<String, dynamic> data) {
    return ScheduleSlot(
      id: id,
      dayIndex: data['dayIndex'],
      slotIndex: data['slotIndex'],
      classId: data['classId'],
      teacherId: data['teacherId'],
      weekKey: data['weekKey'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayIndex': dayIndex,
      'slotIndex': slotIndex,
      'classId': classId,
      'teacherId': teacherId,
      'weekKey': weekKey,
    };
  }
}