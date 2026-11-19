# Aplicación móvil con Flutter, FastAPI y MySQL

El proyecto incluye autenticación JWT, publicaciones, comentarios, valoraciones y mensajería privada 1:1. La API usa FastAPI y SQLAlchemy; la aplicación móvil usa Flutter.

## Requisitos de base de datos

- MySQL 8.0.16 o superior, o MariaDB 10.4 o superior.
- La base se llama `bd_aplicacion_movil` por defecto.
- La configuración local se lee de `backend_API/.env`. Copia `.env.example` como `.env` y configura el usuario y la contraseña de MySQL. El archivo `.env` no se sube a Git.

### Base nueva

Importa `backend_API/bd.sql` únicamente en una base vacía o que aceptes reemplazar. Es un respaldo destructivo: elimina y vuelve a crear tablas y datos semilla. Está preparado con `utf8mb4_unicode_ci` para MySQL y MariaDB de XAMPP.

### Base existente

- `backend_API/migracion_paso1_2.sql`: actualización de la estructura anterior del blog.
- `backend_API/migracion_mensajeria.sql`: agrega las tablas de conversación y mensajes. Haz un respaldo antes de ejecutarla; no elimina datos existentes. En phpMyAdmin selecciona `bd_aplicacion_movil`, abre **Importar** y carga este archivo. Si `root` tiene contraseña, ingrésala al conectar MySQL.

Las tablas de mensajería también se crean al iniciar FastAPI cuando faltan, pero para una actualización controlada se recomienda aplicar la migración SQL y conservar el respaldo.

## Iniciar el backend

```powershell
cd backend_API
python -m pip install -r requirements.txt
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Configura `JWT_SECRET` en `.env`. Genera una clave con:

```powershell
python -c "import secrets; print(secrets.token_hex(32))"
```

La documentación interactiva de la API está en `http://127.0.0.1:8000/docs`.

## Iniciar Flutter Web

En otra terminal:

```powershell
cd flutter_application_3
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

`API_BASE_URL` configura la dirección de FastAPI. Para el emulador Android se puede usar `--dart-define=API_BASE_URL=http://10.0.2.2:8000`; para un dispositivo físico, usa la IP local de la computadora.

## Mensajería interna

Los usuarios autenticados pueden abrir chats privados 1:1 desde **Mensajes** en el blog, desde el menú del administrador o desde **Enviar mensaje** en publicaciones de otros usuarios. Los chats vacíos no aparecen en la bandeja hasta que se envíe el primer mensaje.

Rutas protegidas por JWT:

| Método | Ruta | Función |
|---|---|---|
| GET | `/mensajes/contactos` | Contactos, solo ID y nombre; excluye a la cuenta actual. |
| GET | `/mensajes/conversaciones` | Bandeja, vista previa, fecha y cantidad de mensajes entrantes sin leer. |
| POST | `/mensajes/conversaciones/{usuario_id}` | Abre o crea un chat 1:1; 201 nuevo, 200 existente. |
| GET | `/mensajes/conversaciones/{id}/mensajes?limite=50&antes_de_id={id}` | Página inicial o mensajes anteriores, orden estable por ID. |
| GET | `/mensajes/conversaciones/{id}/mensajes?limite=50&despues_de_id={id}` | Mensajes nuevos para el polling incremental. Con un hilo vacío se usa `despues_de_id=0`. |
| POST | `/mensajes/conversaciones/{id}/mensajes` | Envía texto; el emisor se toma del token y el límite es 2,000 caracteres. |
| POST | `/mensajes/conversaciones/{id}/leidos` | Marca mensajes recibidos como leídos; devuelve `{ "actualizados": n }`. |

Los cursores `antes_de_id` y `despues_de_id` no se usan a la vez. Cada consulta devuelve como máximo 100 mensajes. Los no participantes reciben 404, igual que para un hilo inexistente. La API responde errores con `{ "detail": "..." }`.

Para ver el modelo ER, secuencia de envío/lectura, diccionario de datos y límites de seguridad, consulta [`backend_API/mensajeria.md`](backend_API/mensajeria.md).

## Seguridad y límites de la mensajería

- Solo los dos participantes pueden consultar, enviar o marcar mensajes. El rol de administrador no permite leer chats ajenos.
- Las contraseñas no se incluyen en las respuestas de mensajería. La lista de contactos no expone correos, direcciones ni roles.
- Los textos se guardan sin cifrado de aplicación y no cuentan con cifrado de extremo a extremo. Usa HTTPS fuera del desarrollo local.
- Esta primera versión no incluye límite de frecuencia, bloqueo/reporte, edición o borrado individual de mensajes, chats grupales, archivos, notificaciones push ni presencia.
- Si una cuenta se elimina correctamente, sus conversaciones e historial se eliminan en cascada. La FK existente de comentarios puede impedir borrar ciertas cuentas; la API responde 409 y revierte la operación.