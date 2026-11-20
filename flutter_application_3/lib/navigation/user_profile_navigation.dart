import 'package:flutter/material.dart';

import '../screens/public_user_profile_page.dart';

Future<void> abrirPerfilUsuario(
  BuildContext context, {
  required int userId,
  required String userName,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PublicUserProfilePage(
        userId: userId,
        initialName: userName,
      ),
    ),
  );
}
