/// Dirección base de la API FastAPI (un solo lugar para cambiarla).
///
/// Por defecto apunta a localhost (Flutter Web / escritorio).
/// - Emulador Android:  --dart-define=API_BASE_URL=http://10.0.2.2:8000
/// - Celular físico:    --dart-define=API_BASE_URL=http://IP_DE_TU_PC:8000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
}
