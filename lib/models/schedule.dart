class Schedule {
  const Schedule({
    required this.date,
    required this.month,
    required this.zone,
    required this.vehicle,
    required this.plate,
    required this.shift,
    required this.days,
  });

  final String date;
  final String month;
  final String zone;
  final String vehicle;
  final String plate;
  final String shift;
  final String days;
}

const schedules = [
  Schedule(
    date: '30',
    month: 'OCT\n2026',
    zone: 'Zona Norte',
    vehicle: 'Camión 01',
    plate: 'ABC-123',
    shift: 'Mañana (06:00 - 14:00)',
    days: 'Lun, Mar, Mié, Jue, Vie',
  ),
  Schedule(
    date: '01',
    month: 'NOV\n2026',
    zone: 'Zona Centro',
    vehicle: 'Camión 03',
    plate: 'DEF-456',
    shift: 'Tarde (14:00 - 22:00)',
    days: 'Lun, Mar, Mié, Jue, Vie',
  ),
  Schedule(
    date: '03',
    month: 'NOV\n2026',
    zone: 'Zona Sur',
    vehicle: 'Camión 05',
    plate: 'GHI-789',
    shift: 'Noche (22:00 - 06:00)',
    days: 'Lun, Mar, Mié, Jue, Vie',
  ),
];

class StaffMember {
  const StaffMember(this.role, this.name);

  final String role;
  final String name;
}
