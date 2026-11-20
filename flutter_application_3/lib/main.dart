import 'package:flutter/material.dart';
import 'screens/add_blog_page.dart';
import 'screens/blog_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/login_user_page.dart';
import 'screens/mapa_page.dart';
import 'screens/mensajes_page.dart';
import 'screens/profile_page.dart';
import 'screens/register_user_page.dart';
import 'screens/users_page.dart';
import 'services/sesion_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SesionService.instance.cargar();
  runApp(const LoginApp());
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sesion = SesionService.instance;
    final rutas = <String, WidgetBuilder>{
      '/login': (context) => const LoginPage(),
      '/forgot-password': (context) => const ForgotPasswordPage(),
      '/register': (context) => const RegisterPage(),
      '/users': (context) => const UsersPage(),
      '/blog': (context) => const BlogPage(),
      '/add_blog': (context) => const AddBlogPage(),
      '/add-blog': (context) => const AddBlogPage(),
      '/profile': (context) => const ProfilePage(),
      '/mapa': (context) => const MapaPage(),
      '/mensajes': (context) => const MensajesPage(),
    };

    final String rutaInicial = !sesion.activa
        ? '/login'
        : (sesion.tipoUsuario == 1 ? '/users' : '/blog');

    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.darkMode,
      builder: (context, darkMode, _) => MaterialApp(
        navigatorKey: SesionService.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Aplicación móvil con FastAPI',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
        initialRoute: rutaInicial,
        onGenerateInitialRoutes: (nombre) {
          return [
            MaterialPageRoute<void>(
              settings: RouteSettings(
                name: nombre,
                arguments: sesion.activa ? sesion.usuario : null,
              ),
              builder: rutas[nombre]!,
            ),
          ];
        },
        routes: rutas,
      ),
    );
  }
}
