# 📰 Instrucciones para actualizar la base de datos

Este conjunto de scripts permite tener todos los usuarios y las 15 noticias reales funcionando en la base de datos `bd_aplicacion_movil`.

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

## Paso 2: Colocar las 15 imágenes

Copia las 15 imágenes en la carpeta:

```
backend_API/uploads/
```

| # | Archivo | Tema sugerido |
|---|---|---|
| 1 | `noticia_f1_verstappen.jpg` | Max Verstappen / F1 / Red Bull Racing |
| 2 | `noticia_nvidia_5090.jpg` | Tarjeta gráfica NVIDIA RTX 5090 |
| 3 | `noticia_champions.jpg` | Real Madrid / Champions League |
| 4 | `noticia_amd_ryzen.jpg` | Procesador AMD Ryzen 9 |
| 5 | `noticia_marte_agua.jpg` | Planeta Marte / NASA |
| 6 | `noticia_gta6.jpg` | GTA VI / Grand Theft Auto |
| 7 | `noticia_chatgpt.jpg` | ChatGPT / OpenAI |
| 8 | `noticia_america.jpg` | Club América / Liga MX |
| 9 | `noticia_iphone17.jpg` | iPhone 17 / Apple |
| 10 | `noticia_hamilton_ferrari.jpg` | Lewis Hamilton con Ferrari |
| 11 | `noticia_avatar3.jpg` | Avatar 3 / Película |
| 12 | `noticia_python.jpg` | Python / Programación |
| 13 | `noticia_badbunny.jpg` | Bad Bunny / Concierto |
| 14 | `noticia_tesla_robotaxi.jpg` | Tesla Robotaxi / Auto autónomo |
| 15 | `noticia_switch2.jpg` | Nintendo Switch 2 |

---

## Paso 3: Insertar las noticias

Ejecuten el archivo:

```
base_datos_actualizada/insertar_noticias.sql
```

### ¿Cómo ejecutarlo?

**Desde phpMyAdmin:**
1. Selecciona la base de datos `bd_aplicacion_movil`.
2. Ve a la pestaña **Importar**.
3. Selecciona `insertar_usuarios.sql` y dale a **Continuar**.
4. Repite el proceso con `insertar_noticias.sql`.

**Desde terminal MySQL:**
```bash
mysql -u root -p bd_aplicacion_movil < base_datos_actualizada/insertar_usuarios.sql
mysql -u root -p bd_aplicacion_movil < base_datos_actualizada/insertar_noticias.sql
```

---

## ¿Qué hace el script de noticias?
1. Limpia cualquier publicación vieja que contenga "prueba", "pruev", "HOLA", etc.
2. Inserta las 15 noticias reales con codificación `utf8mb4` (con tildes y eñes correctas).
3. Añade 10 comentarios variados entre diferentes usuarios.
