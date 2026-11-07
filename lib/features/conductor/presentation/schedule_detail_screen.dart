import 'package:flutter/material.dart';

import '../../../models/schedule.dart';

class ScheduleDetailScreen extends StatefulWidget {
  const ScheduleDetailScreen({super.key, required this.schedule});

  final Schedule schedule;

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  final _staff = const [
    StaffMember('Conductor (Tú)', 'Juan Pérez'),
    StaffMember('Ayudante', 'Carlos López'),
    StaffMember('Ayudante', 'Luis García'),
  ];
  late List<bool> _present;

  bool get _everyonePresent => _present.every((present) => present);

  @override
  void initState() {
    super.initState();
    _present = List<bool>.filled(_staff.length, true);
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programación del día'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBCE8CE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF159957)),
                SizedBox(width: 10),
                Text(
                  'Hay programación para hoy',
                  style: TextStyle(
                    color: Color(0xFF147A47),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                children: [
                  _DetailLine(
                    Icons.calendar_month_outlined,
                    'Fecha',
                    'Lunes, 27 de octubre de 2025',
                  ),
                  const Divider(height: 24),
                  _DetailLine(
                    Icons.location_on_outlined,
                    'Zona',
                    schedule.zone,
                  ),
                  const SizedBox(height: 17),
                  _DetailLine(
                    Icons.local_shipping_outlined,
                    'Vehículo',
                    '${schedule.vehicle} (${schedule.plate})',
                  ),
                  const SizedBox(height: 17),
                  _DetailLine(
                    Icons.groups_outlined,
                    'Ayudantes',
                    'Carlos López\nLuis García',
                  ),
                  const SizedBox(height: 17),
                  _DetailLine(Icons.schedule_outlined, 'Turno', schedule.shift),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Estado de asistencia del personal',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            child: Column(
              children: List.generate(_staff.length, (index) {
                final member = _staff[index];
                final present = _present[index];
                return ListTile(
                  dense: true,
                  onTap: () => setState(() => _present[index] = !present),
                  leading: Icon(
                    index == 0 ? Icons.badge_outlined : Icons.person_outline,
                    color: const Color(0xFF0B63CE),
                  ),
                  title: Text(
                    member.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(member.role),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        present ? Icons.check_circle : Icons.cancel,
                        color: present
                            ? const Color(0xFF159957)
                            : const Color(0xFFE05252),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        present ? 'Presente' : 'Ausente',
                        style: TextStyle(
                          color: present
                              ? const Color(0xFF147A47)
                              : const Color(0xFFC13D3D),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _everyonePresent
                  ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recorrido iniciado correctamente'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    )
                  : null,
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Iniciar recorrido'),
            ),
          ),
          const SizedBox(height: 9),
          Center(
            child: Text(
              _everyonePresent
                  ? 'Todo el personal está presente'
                  : 'Todos deben estar presentes para iniciar',
              style: TextStyle(
                color: _everyonePresent
                    ? const Color(0xFF147A47)
                    : const Color(0xFFC13D3D),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFF0B63CE), size: 22),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF173B62),
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
