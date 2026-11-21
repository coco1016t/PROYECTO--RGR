# 📰 Instrucciones para actualizar la base de datos

Este conjunto de scripts permite tener todos los usuarios y las 15 noticias reales funcionando en la base de datos `bd_aplicacion_movil`.

> [!NOTE]
> **Las 15 imágenes ya están incluidas en el repositorio de GitHub** dentro de `backend_API/uploads/`. Solo necesitan hacer `git pull` para tenerlas en su proyecto sin tener que descargarlas manualmente.

---

## Paso 1: Insertar los usuarios (si no los tienen)

Para que las noticias tengan sus autores correspondientes y no fallen por clave foránea, ejecuten primero el archivo:

```
base_datos_actualizada/insertar_usuarios.sql
```

### Usuarios incluidos:
* **andres** (`andres@gmail.com`) - Administrador
* **reynaldo** (`reynaldo@gmail.com`) - Administrador
* **gerardo** (`gerardo@gmail.com`) - Usuario General
* **luis** (`luis@gmail.com`) - Usuario General
* **Adriana** (`adri@gmail.com`) - Usuario General
* **rube azpeitia** (`rubas@gmail.com`) - Usuario General
* **Jose perez** (`uteq@gmail.com`) - Usuario General
* **Andres** (`andresgonzalez@gmail.com`) - Usuario General

*El script usa `ON DUPLICATE KEY UPDATE`, por lo que si ya tienen alguno de estos usuarios, no causará ningún error.*

---

## Paso 2: Insertar las noticias

Ejecuten el archivo:

```
base_datos_actualizada/insertar_noticias.sql
```

### ¿Cómo ejecutar los scripts?

**Desde phpMyAdmin:**
1. Selecciona la base de datos `bd_aplicacion_movil`.
2. Ve a la pestaña **Importar**.
3. Selecciona `insertar_usuarios.sql` y haz clic en **Continuar**.
4. Repite el proceso seleccionando `insertar_noticias.sql`.

**Desde terminal MySQL:**
```bash
mysql -u root -p bd_aplicacion_movil < base_datos_actualizada/insertar_usuarios.sql
mysql -u root -p bd_aplicacion_movil < base_datos_actualizada/insertar_noticias.sql
```

---

## ¿Qué hace el script de noticias?
1. Limpia cualquier publicación vieja que contenga "prueba", "pruev", "HOLA", etc.
2. Inserta las 15 noticias reales con codificación `utf8mb4` (con tildes y eñes correctas).
3. Añade 10 comentarios variados entre diferentes usuarios asociados a las imágenes que ya están en `backend_API/uploads/`.
