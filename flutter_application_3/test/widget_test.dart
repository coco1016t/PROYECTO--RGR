// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_3/main.dart';
import 'package:flutter_application_3/screens/users_page.dart';

void main() {
  testWidgets('login page fits on a narrow screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LoginApp());
    await tester.pumpAndSettle();

    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('INGRESAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('users page exposes the admin navigation drawer',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UsersPage(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('Gestión de usuarios'), findsWidgets);
    expect(find.text('Registrar usuario'), findsOneWidget);
    expect(find.text('Agregar blog'), findsOneWidget);
    expect(find.text('Mi perfil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
