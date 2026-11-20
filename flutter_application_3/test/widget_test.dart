// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:url_launcher/link.dart';

import 'package:flutter_application_3/main.dart';
import 'package:flutter_application_3/screens/blog_page.dart';
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
    expect(find.byIcon(Icons.map_outlined), findsNothing);
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
    testWidgets(
        'blog fills the available width with one create action at $width',
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
      },
          () => MockClient((_) async =>
              http.Response('[{"id_blog":1,"titulo":"Ejemplo"}]', 200)));
    });
  }

  testWidgets('my posts can be edited and deleted after confirmation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final post = {
      'id_blog': 42,
      'titulo': 'Publicación original',
      'descripcion': 'Texto original',
      'tags': 'comunidad',
    };
    var eliminado = false;
    var intentosEliminar = 0;
    final editar = find.text('Editar');
    final eliminar = find.text('Eliminar');

    await http.runWithClient(() async {
      await abrirRuta(tester, '/blog');
      expect(editar, findsNothing);
      expect(eliminar, findsNothing);
      await tester.tap(find.text('Mis publicaciones'));
      await tester.pumpAndSettle();

      await tester.tap(editar);
      await tester.pumpAndSettle();
      expect(find.text('Editar publicación'), findsOneWidget);
      expect(find.text('Publicación original'), findsOneWidget);
      expect(find.text('Texto original'), findsOneWidget);
      expect(find.text('comunidad'), findsOneWidget);
      await tester.enterText(
          find.byType(TextFormField).first, 'Título editado');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(find.text('Tus publicaciones'), findsOneWidget);
      expect(find.text('Título editado'), findsOneWidget);

      await tester.tap(eliminar);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(intentosEliminar, 0);

      final confirmar = find.widgetWithText(FilledButton, 'Eliminar');
      await tester.tap(eliminar);
      await tester.pumpAndSettle();
      await tester.tap(confirmar);
      await tester.pumpAndSettle();
      expect(find.text('Título editado'), findsOneWidget);
      expect(find.text('No se pudo eliminar'), findsOneWidget);

      await tester.tap(eliminar);
      await tester.pumpAndSettle();
      await tester.tap(confirmar);
      await tester.pumpAndSettle();
      expect(intentosEliminar, 2);
      expect(find.byType(PostCard), findsNothing);
      expect(find.text('Aún no has publicado nada.'), findsOneWidget);
    },
        () => MockClient((request) async {
              const headers = {
                'content-type': 'application/json; charset=utf-8'
              };
              if (request.method == 'PUT') {
                expect(request.url.path, '/blog/42');
                final formulario = utf8.decode(request.bodyBytes);
                expect(formulario, contains('Título editado'));
                expect(formulario, isNot(contains('filename=')));
                post['titulo'] = 'Título editado';
                return http.Response(jsonEncode(post), 200, headers: headers);
              }
              if (request.method == 'DELETE') {
                expect(request.url.path, '/blog/42');
                if (++intentosEliminar == 1) {
                  return http.Response('{"detail":"No se pudo eliminar"}', 500,
                      headers: headers);
                }
                eliminado = true;
                return http.Response('', 204);
              }
              return http.Response(jsonEncode(eliminado ? [] : [post]), 200,
                  headers: headers);
            }));
  });

  for (final (ruta, ancho, alto) in [
    ('/blog', 320.0, 480.0),
    ('/blog', 1280.0, 800.0),
    ('/users', 320.0, 360.0),
  ]) {
    testWidgets('map opens from $ruta at $ancho and keeps its attribution',
        (tester) async {
      tester.view.physicalSize = Size(ancho, alto);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final tesela = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=',
      );
      await http.runWithClient(() async {
        await abrirRuta(tester, ruta);
        final abrirMenu = find.byTooltip('Open navigation menu');
        if (abrirMenu.evaluate().isNotEmpty) {
          await tester.tap(abrirMenu);
          await tester.pumpAndSettle();
        }
        final opcionMapa = find.text('Mapa de lugares');
        await tester.ensureVisible(opcionMapa);
        await tester.pumpAndSettle();
        expect(opcionMapa.hitTestable(), findsOneWidget);
        await tester.tap(opcionMapa);
        await tester.pumpAndSettle();

        expect(find.text('Lugares de mi comunidad'), findsOneWidget);
        final credito = find.text('© OpenStreetMap contributors').hitTestable();
        expect(credito, findsOneWidget);
        expect(tester.widget<Link>(find.byType(Link)).uri.toString(),
            'https://www.openstreetmap.org/copyright');
        final posicion = tester.getBottomRight(credito);
        expect(tester.getBottomRight(find.byType(FloatingActionButton)).dy,
            lessThan(tester.getTopLeft(credito).dy));

        final mapa = MapController.of(tester.element(find.byType(TileLayer)));
        final centroInicial = mapa.camera.center;
        await tester.drag(find.byType(FlutterMap), const Offset(60, 40));
        await tester.pumpAndSettle();
        expect(mapa.camera.center, isNot(centroInicial));
        mapa.move(mapa.camera.center, mapa.camera.zoom + 1);
        await tester.pumpAndSettle();
        expect(tester.getBottomRight(credito), posicion);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(FlutterMap), findsNothing);
        expect(find.byType(ruta == '/blog' ? BlogPage : UsersPage),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      },
          () => MockClient((request) async {
                if (request.url.host == 'tile.openstreetmap.org') {
                  return http.Response.bytes(tesela, 200);
                }
                return http.Response('[]', 200);
              }));
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
