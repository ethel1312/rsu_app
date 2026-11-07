import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rsu_app/main.dart';
import 'package:rsu_app/features/conductor/presentation/schedule_detail_screen.dart';
import 'package:rsu_app/models/schedule.dart';

void main() {
  testWidgets('login navigates to the schedules screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RsuApp());
    await tester.enterText(find.byType(TextFormField).first, 'juan.perez');
    await tester.enterText(find.byType(TextFormField).last, 'demo123');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Mis programaciones'), findsOneWidget);
    expect(find.text('Programaciones'), findsOneWidget);
  });

  testWidgets('route button requires all staff present', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ScheduleDetailScreen(schedule: schedules.first)),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(find.text('Iniciar recorrido'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Iniciar recorrido'),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton && widget.onPressed != null,
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Carlos López'));
    await tester.pump();

    expect(
      find.ancestor(
        of: find.text('Iniciar recorrido'),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton && widget.onPressed != null,
        ),
      ),
      findsNothing,
    );
  });
}
