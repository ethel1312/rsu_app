import 'package:flutter/material.dart';
import '../../../core/api/conductor_api.dart';

import '../../../models/schedule.dart';

class ScheduleDetailScreen extends StatefulWidget {
  const ScheduleDetailScreen({super.key, required this.schedule, this.api});
  final ConductorApi? api;

  final Schedule schedule;

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> {
  ConductorApi get _api => widget.api ?? ConductorApi.instance;
  ScheduleDetail? _detail;
  String? _error;
  bool _loading = true;
  bool _starting = false;

  List<StaffMember> get _staff => _detail?.staff ?? [];
  bool get _everyonePresent =>
      _staff.isNotEmpty && _staff.every((member) => member.present);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _api.detail(widget.schedule);
      if (mounted) setState(() => _detail = detail);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'No se pudo cargar el detalle.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final detail = await _api.start(widget.schedule);
      if (!mounted) return;
      setState(() => _detail = detail);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorrido iniciado correctamente')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'No se pudo iniciar el recorrido.',
          ),
        ),
      );
      await _load();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _detail?.schedule ?? widget.schedule;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programación del día'),
        leading: const BackButton(),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar asistencia',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBCE8CE)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF159957)),
                      SizedBox(width: 10),
                      Text(
                        'Programación: ${schedule.fullDate}',
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
                          schedule.fullDate,
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
                          _staff
                              .where((member) => member.id != _staff.first.id)
                              .map((member) => member.name)
                              .join('\n'),
                        ),
                        const SizedBox(height: 17),
                        _DetailLine(
                          Icons.schedule_outlined,
                          'Turno',
                          schedule.shift,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Estado de asistencia del personal',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  child: Column(
                    children: List.generate(_staff.length, (index) {
                      final member = _staff[index];
                      final present = member.present;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          index == 0
                              ? Icons.badge_outlined
                              : Icons.person_outline,
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
                    onPressed: (_detail?.canStart ?? false) && !_starting
                        ? _start
                        : null,
                    icon: const Icon(Icons.navigation_rounded),
                    label: Text(
                      _starting
                          ? 'Iniciando...'
                          : (_detail?.started ?? false)
                          ? 'Recorrido iniciado'
                          : 'Iniciar recorrido',
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Center(
                  child: Text(
                    (_detail?.started ?? false)
                        ? 'El recorrido ya fue registrado'
                        : _everyonePresent
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
