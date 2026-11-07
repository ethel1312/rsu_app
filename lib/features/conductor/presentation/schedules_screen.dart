import 'package:flutter/material.dart';
import '../../../core/api/conductor_api.dart';

import '../../auth/presentation/login_screen.dart';
import '../../../models/schedule.dart';
import 'schedule_detail_screen.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key, this.api});
  final ConductorApi? api;

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  ConductorApi get _api => widget.api ?? ConductorApi.instance;
  late Future<List<Schedule>> _schedules;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _schedules = _api.schedules();
  }

  Future<void> _reload() async {
    final request = _api.schedules();
    setState(() => _schedules = request);
    try {
      await request;
    } catch (_) {
      /* FutureBuilder muestra el error. */
    }
  }

  Future<void> _signOut() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await _api.logout();
    } on ApiException catch (error) {
      if (error.status != 401) {
        if (mounted) {
          setState(() => _loggingOut = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
        return;
      }
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(api: _api)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis programaciones'),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Menú',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE2EEFF),
              child: Icon(Icons.person, color: Colors.blue[700], size: 20),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.recycling, color: Color(0xFF0B63CE)),
                title: Text(
                  'RSU',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text('Panel del conductor'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Mis programaciones'),
                selected: true,
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: _loggingOut ? null : _signOut,
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Schedule>>(
        future: _schedules,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            final expired = error is ApiException && error.status == 401;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error is ApiException
                          ? error.message
                          : 'No se pudieron cargar las programaciones.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: expired ? _signOut : _reload,
                      child: Text(expired ? 'Volver a ingresar' : 'Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final schedules = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                _DriverCard(driver: _api.driver!),
                const SizedBox(height: 26),
                Text(
                  'Programaciones',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (schedules.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'No tienes programaciones pendientes.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ...schedules.map(
                  (schedule) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ScheduleCard(schedule: schedule, api: _api),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final Driver driver;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFEAF3FF), Color(0xFFF6FAFF)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFD7E7FA)),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFBBD9FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Color(0xFF0B63CE), size: 30),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conductor', style: TextStyle(color: Color(0xFF5F7085))),
            SizedBox(height: 3),
            Text(driver.name, style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 3),
            Text(
              'DNI: ${driver.dni}',
              style: TextStyle(color: Color(0xFF5F7085)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.api});
  final ConductorApi api;

  final Schedule schedule;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ScheduleDetailScreen(schedule: schedule, api: api),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFF0B73DF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    schedule.date,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    schedule.month,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.05,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoLine(
                    Icons.location_on_outlined,
                    schedule.zone,
                    bold: true,
                  ),
                  const SizedBox(height: 7),
                  _InfoLine(
                    Icons.local_shipping_outlined,
                    '${schedule.vehicle} (${schedule.plate})',
                  ),
                  const SizedBox(height: 5),
                  _InfoLine(Icons.schedule_outlined, schedule.shift),
                  const SizedBox(height: 5),
                  _InfoLine(Icons.event_repeat_outlined, schedule.days),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.blueGrey[400]),
          ],
        ),
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text, {this.bold = false});

  final IconData icon;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: const Color(0xFF0B63CE)),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: bold ? const Color(0xFF134B87) : const Color(0xFF5F7085),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    ],
  );
}
