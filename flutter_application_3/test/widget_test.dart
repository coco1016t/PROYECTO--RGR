// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_3/main.dart';
import 'package:flutter_application_3/screens/forgot_password_page.dart';
import 'package:flutter_application_3/screens/users_page.dart';
import 'package:flutter_application_3/theme/app_theme.dart';
import 'package:flutter_application_3/widgets/post_card.dart';

void main() {
  testWidgets('login page fits on a narrow screen',
      (WidgetTester tester) async {
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

  testWidgets('forgot password page shows email and new password fields',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: ForgotPasswordPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('RECUPERAR CONTRASEÑA'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Nueva contraseña'), findsOneWidget);
    expect(find.text('ACTUALIZAR CONTRASEÑA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login link opens forgot password page',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LoginApp());
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('RECUPERAR CONTRASEÑA'), findsOneWidget);
    expect(find.text('Nueva contraseña'), findsOneWidget);
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

  for (final width in [390.0, 1280.0, 1920.0]) {
    testWidgets('blog fills the available width with one create action at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await http.runWithClient(() async {
        await abrirRuta(tester, '/blog');

        final publicacion = find.byType(PostCard);
        expect(publicacion, findsOneWidget);
        expect(tester.getTopRight(publicacion).dx, width - 20);
        expect(find.text('Destacadas'), findsNothing);

        expect(find.text('Mis publicaciones'), findsOneWidget);
        await tester.tap(find.text('Mis publicaciones'));
        await tester.pumpAndSettle();
        expect(find.text('Tus publicaciones'), findsOneWidget);

        if (width < 1120) {
          await tester.tap(find.byTooltip('Open navigation menu'));
          await tester.pumpAndSettle();
        }
        expect(find.text('Mis publicaciones'), findsOneWidget);
        expect(find.text('Mensajes'), findsOneWidget);
        expect(find.byTooltip('Mensajes'), findsNothing);
        expect(find.text('Cerrar sesión'), findsOneWidget);
        if (width < 1120) {
          tester.state<ScaffoldState>(find.byType(Scaffold)).closeDrawer();
          await tester.pumpAndSettle();
        }

        final crear = find.byTooltip('Crear publicación');
        final botonFlotante = find.byType(FloatingActionButton);
        expect(crear, findsOneWidget);
        expect(botonFlotante, findsOneWidget);
        expect(tester.widget<FloatingActionButton>(botonFlotante).mini, isTrue);
        await tester.tap(crear);
        await tester.pumpAndSettle();
        expect(find.text('Nueva publicación'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }, () => MockClient((_) async =>
          http.Response('[{"id_blog":1,"titulo":"Ejemplo"}]', 200)));
    });
  }

  testWidgets('admin screens and dialogs inherit the shared theme',
      (tester) async {
    addTearDown(() => AppTheme.darkMode.value = false);

    await http.runWithClient(() async {
      await abrirRuta(tester, '/users');
      final users = find.byType(UsersPage);
      expect(Theme.of(tester.element(users)).colorScheme.primary,
          const Color(0xFF527D7B));

      await tester.tap(find.byTooltip('Activar modo oscuro'));
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(users)).brightness, Brightness.dark);

      await tester.tap(find.byTooltip('Nuevo usuario'));
      await tester.pumpAndSettle();
      final dialogTheme = Theme.of(tester.element(find.byType(AlertDialog)));
      expect(
          dialogTheme.colorScheme.primary, AppTheme.dark.colorScheme.primary);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registrar usuario'));
      await tester.pumpAndSettle();
      expect(find.text('Tipo de usuario'), findsOneWidget);
      expect(
          Theme.of(tester.element(find.byType(DropdownButtonFormField<int>)))
              .brightness,
          Brightness.dark);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => http.Response('[]', 200)));
  });
}

Future<void> abrirRuta(WidgetTester tester, String ruta) async {
  await tester.pumpWidget(const LoginApp());
  tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(ruta);
  await tester.pumpAndSettle();
}
