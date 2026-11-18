# Aplicacion movil con Flutter y FastAPI

El proyecto usa MySQL (`bd_aplicacion_movil`), sesiones JWT y autor de posts y comentarios.

## Iniciar el backend

```powershell
cd backend_API
python -m pip install -r requirements.txt
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

La conexion se lee de `backend_API/.env`. Copia `.env.example` como `.env` dentro de `backend_API` y configura la contrasena de MySQL. El archivo `.env` esta excluido de Git, asi cada integrante conserva su propia clave. El backend apunta por defecto a `bd_aplicacion_movil` y conserva sus usuarios y contrasenas.

Para una base nueva, importa `backend_API/bd.sql`: ya crea `blog.usr_id`, su relacion con `usuario` y asigna los posts del respaldo al usuario 1.
El archivo es un respaldo completo que elimina y recrea las tablas; usalo solo en una base nueva o que quieras reemplazar.

`backend_API/migracion_paso1_2.sql` queda para quien ya tenga una base de la version anterior. Ejecutalo una vez en esa base; no se necesita al importar el `bd.sql` actualizado y no cambia contrasenas.

Configura tambien `JWT_SECRET` en `.env`. Genera una clave con `python -c "import secrets; print(secrets.token_hex(32))"`.

## Iniciar Flutter Web

En otra terminal:

```powershell
cd flutter_application_3
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

`API_BASE_URL` configura todos los servicios. La documentacion interactiva esta en `http://127.0.0.1:8000/docs`.
