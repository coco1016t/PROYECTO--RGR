import 'package:flutter/material.dart';
import 'screens/add_blog_page.dart';
import 'screens/blog_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/login_user_page.dart';
import 'screens/mapa_page.dart';
import 'screens/profile_page.dart';
import 'screens/register_user_page.dart';
import 'screens/users_page.dart';
import 'services/sesion_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Recupera la sesión guardada (si el token aún no expira).
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
    };

    // Con sesión vigente se salta el login: admin -> /users, usuario -> /blog.
    final String rutaInicial = !sesion.activa
        ? '/login'
        : (sesion.tipoUsuario == 1 ? '/users' : '/blog');

    return MaterialApp(
      navigatorKey: SesionService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Aplicación móvil con FastAPI',
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
    );
  }
}