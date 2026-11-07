import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rsu_app/main.dart';
import 'package:rsu_app/core/api/conductor_api.dart';
import 'package:rsu_app/features/conductor/presentation/schedule_detail_screen.dart';
import 'package:rsu_app/models/schedule.dart';

const schedule = Schedule(
  id: 41,
  serviceDate: '2026-11-10',
  zone: 'Zona asignada',
  vehicle: 'Camión',
  plate: 'XYZ-001',
  shift: 'Mañana',
  days: 'Mar',
);

class FakeApi extends ConductorApi {
  FakeApi({this.rejectLogin = false, this.present = false}) {
    driver = const Driver(id: 12, name: 'Conductor real', dni: '87654321');
  }
  final bool rejectLogin;
  final bool present;
  bool started = false;
  @override
  Future<void> signIn(String username, String password) async {
    if (rejectLogin) {
      throw const ApiException('Credenciales incorrectas', status: 401);
    }
  }

  @override
  Future<List<Schedule>> schedules() async => [schedule];
  ScheduleDetail get value => ScheduleDetail(
    schedule: schedule,
    staff: [
      const StaffMember(
        id: 12,
        role: 'Conductor (Tú)',
        name: 'Conductor real',
        present: true,
      ),
      StaffMember(
        id: 13,
        role: 'Ayudante',
        name: 'Ayudante asignado',
        present: present,
      ),
    ],
    started: started,
    canStart: present && !started,
  );
  @override
  Future<ScheduleDetail> detail(Schedule schedule) async => value;
  @override
  Future<ScheduleDetail> start(Schedule schedule) async {
    started = true;
    return value;
  }
}

void main() {
  testWidgets('rechazo del servicio conserva el login y muestra el error', (
    tester,
  ) async {
    await tester.pumpWidget(RsuApp(api: FakeApi(rejectLogin: true)));
    await tester.enterText(find.byType(TextFormField).first, '87654321');
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.ensureVisible(find.text('Ingresar'));
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();
    expect(find.text('Credenciales incorrectas'), findsOneWidget);
    expect(find.text('Mis programaciones'), findsNothing);
  });

  testWidgets('login carga el perfil y las programaciones de la API', (
    tester,
  ) async {
    await tester.pumpWidget(RsuApp(api: FakeApi()));
    await tester.enterText(find.byType(TextFormField).first, '87654321');
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.ensureVisible(find.text('Ingresar'));
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();
    expect(find.text('Conductor real'), findsOneWidget);
    expect(find.text('DNI: 87654321'), findsOneWidget);
    expect(find.text('Zona asignada'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsNothing);
  });

  testWidgets(
    'la asistencia viene del servidor y no se puede cambiar tocando al personal',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScheduleDetailScreen(schedule: schedule, api: FakeApi()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      await tester.tap(find.text('Ayudante asignado'));
      await tester.pump();
      expect(find.text('Ausente'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Iniciar recorrido'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'iniciar recorrido espera confirmación del servidor y bloquea el segundo inicio',
    (tester) async {
      final api = FakeApi(present: true);
      await tester.pumpWidget(
        MaterialApp(
          home: ScheduleDetailScreen(schedule: schedule, api: api),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();
      await tester.tap(find.text('Iniciar recorrido'));
      await tester.pumpAndSettle();
      expect(api.started, isTrue);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Recorrido iniciado'),
      );
      expect(button.onPressed, isNull);
    },
  );
}
