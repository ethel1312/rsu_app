class Driver {
  const Driver({required this.id, required this.name, required this.dni});
  final int id;
  final String name;
  final String dni;
  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    dni: json['dni'] as String,
  );
}

class Schedule {
  const Schedule({
    required this.id,
    required this.serviceDate,
    required this.zone,
    required this.vehicle,
    required this.plate,
    required this.shift,
    required this.days,
  });
  final int id;
  final String serviceDate;
  final String zone;
  final String vehicle;
  final String plate;
  final String shift;
  final String days;
  String get date => serviceDate.substring(8, 10);
  String get month {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    return '${months[int.parse(serviceDate.substring(5, 7)) - 1]}\n${serviceDate.substring(0, 4)}';
  }

  String get fullDate =>
      '${serviceDate.substring(8, 10)}/${serviceDate.substring(5, 7)}/${serviceDate.substring(0, 4)}';
  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id: (json['id'] as num).toInt(),
    serviceDate: json['service_date'] as String,
    zone: json['zone'] as String,
    vehicle: json['vehicle'] as String,
    plate: json['plate'] as String,
    shift: json['shift'] as String,
    days: json['days'] as String,
  );
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.role,
    required this.name,
    required this.present,
  });
  final int id;
  final String role;
  final String name;
  final bool present;
  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    id: (json['id'] as num).toInt(),
    role: json['role'] as String,
    name: json['name'] as String,
    present: json['present'] as bool,
  );
}

class ScheduleDetail {
  const ScheduleDetail({
    required this.schedule,
    required this.staff,
    required this.started,
    required this.canStart,
  });
  final Schedule schedule;
  final List<StaffMember> staff;
  final bool started;
  final bool canStart;
  factory ScheduleDetail.fromJson(Map<String, dynamic> json) => ScheduleDetail(
    schedule: Schedule.fromJson(json),
    staff: (json['staff'] as List)
        .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
        .toList(),
    started: json['started'] as bool,
    canStart: json['can_start'] as bool,
  );
}
