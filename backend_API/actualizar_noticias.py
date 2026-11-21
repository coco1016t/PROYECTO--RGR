# -*- coding: utf-8 -*-
import pymysql

conn = pymysql.connect(
    host='127.0.0.1',
    user='root',
    password='',
    database='bd_aplicacion_movil',
    charset='utf8mb4'
)

noticias = [
    (
        'Verstappen consigue su cuarto título mundial de F1',
        'Max Verstappen se coronó campeón del mundo de Fórmula 1 por cuarta vez consecutiva tras una temporada dominante con Red Bull Racing. El piloto neerlandés sumó 19 victorias en 23 carreras, consolidándose como uno de los pilotos más exitosos en la historia del deporte.',
        '/uploads/noticia_f1_verstappen.jpg',
        'f1,deportes,verstappen',
        18
    ),
    (
        'NVIDIA presenta la RTX 5090: el GPU más potente del mundo',
        'NVIDIA reveló oficialmente la GeForce RTX 5090 con arquitectura Blackwell, 32 GB de GDDR7 y un rendimiento hasta 2 veces superior a la generación anterior. Esta tarjeta gráfica promete revolucionar el gaming en 4K y la inteligencia artificial generativa para creadores de contenido.',
        '/uploads/noticia_nvidia_5090.jpg',
        'nvidia,tecnologia,gaming',
        5
    ),
    (
        'Real Madrid gana su decimosexta Champions League',
        'El Real Madrid venció 2-1 al Manchester City en la final de la UEFA Champions League disputada en el Allianz Arena de Múnich. Vinícius Jr. anotó el gol decisivo en el minuto 87, dándole al club merengue su decimosexto título europeo y consolidando su legado como el rey de Europa.',
        '/uploads/noticia_champions.jpg',
        'futbol,champions,realmadrid',
        2
    ),
    (
        'AMD Ryzen 9 9950X: el procesador que desafía a Intel',
        'AMD lanzó su nuevo procesador insignia Ryzen 9 9950X basado en la arquitectura Zen 5 con 16 núcleos y 32 hilos. Las pruebas de rendimiento muestran mejoras del 40% en multihilo respecto a la generación anterior, posicionando a AMD como líder indiscutible en rendimiento por vatio.',
        '/uploads/noticia_amd_ryzen.jpg',
        'amd,tecnologia,procesadores',
        6
    ),
    (
        'La NASA confirma agua líquida bajo la superficie de Marte',
        'Científicos de la NASA anunciaron el descubrimiento de evidencia definitiva de agua líquida bajo la superficie de Marte, gracias a datos recolectados por el rover Perseverance. Este hallazgo aumenta significativamente las posibilidades de encontrar vida microbiana en el planeta rojo.',
        '/uploads/noticia_marte_agua.jpg',
        'ciencia,nasa,marte',
        14
    ),
    (
        'GTA VI confirma fecha de lanzamiento para otoño 2026',
        'Rockstar Games finalmente confirmó que Grand Theft Auto VI se lanzará en octubre de 2026 para PlayStation 5 y Xbox Series X. El juego estará ambientado en Vice City con un mapa tres veces más grande que GTA V y presentará a dos protagonistas jugables por primera vez en la saga.',
        '/uploads/noticia_gta6.jpg',
        'gaming,gta,rockstar',
        20
    ),
    (
        'ChatGPT alcanza los 500 millones de usuarios activos',
        'OpenAI reportó que ChatGPT superó los 500 millones de usuarios activos mensuales, convirtiéndose en la aplicación de inteligencia artificial más utilizada del mundo. La empresa también anunció nuevas funciones de razonamiento avanzado y generación de código en tiempo real.',
        '/uploads/noticia_chatgpt.jpg',
        'ia,tecnologia,openai',
        16
    ),
    (
        'Club América se corona bicampeón de la Liga MX',
        'El Club América se coronó bicampeón de la Liga MX tras vencer al Monterrey en una emocionante final. Con goles de Henry Martín y Alejandro Zendejas, las Águilas sumaron su decimoquinto título liguero, reforzando su posición como el equipo más ganador del fútbol mexicano.',
        '/uploads/noticia_america.jpg',
        'futbol,ligamx,america',
        2
    ),
    (
        'Apple presenta el iPhone 17 con diseño completamente renovado',
        'Apple reveló el iPhone 17 con un diseño ultra delgado de solo 6.9mm, pantalla ProMotion de 120Hz en todos los modelos y el nuevo chip A19 Pro fabricado en proceso de 2nm. La cámara principal de 48MP con sensor más grande promete fotos de nivel profesional incluso en condiciones de poca luz.',
        '/uploads/noticia_iphone17.jpg',
        'apple,tecnologia,iphone',
        5
    ),
    (
        'Lewis Hamilton debuta con Ferrari en el GP de Australia',
        'Lewis Hamilton hizo su debut oficial con la Scuderia Ferrari en el Gran Premio de Australia, logrando un impresionante segundo lugar en su primera carrera con el equipo italiano. El siete veces campeón del mundo declaró sentirse rejuvenecido y listo para luchar por su octavo título mundial.',
        '/uploads/noticia_hamilton_ferrari.jpg',
        'f1,deportes,hamilton,ferrari',
        18
    ),
    (
        'Avatar 3 rompe récords de taquilla en su primer fin de semana',
        'Avatar: Fire and Ash recaudó 650 millones de dólares en su primer fin de semana a nivel mundial, superando todos los récords de apertura en la historia del cine. James Cameron vuelve a demostrar su dominio en el cine de ciencia ficción con efectos visuales que empujan los límites de la tecnología.',
        '/uploads/noticia_avatar3.jpg',
        'cine,peliculas,avatar',
        14
    ),
    (
        'Python supera a JavaScript como el lenguaje más popular del mundo',
        'Según el índice TIOBE de noviembre 2026, Python superó definitivamente a JavaScript como el lenguaje de programación más utilizado globalmente. El crecimiento explosivo de la inteligencia artificial y el machine learning han impulsado la adopción de Python en universidades y empresas por igual.',
        '/uploads/noticia_python.jpg',
        'programacion,tecnologia,python',
        6
    ),
    (
        'Bad Bunny anuncia gira mundial 2027 con 80 fechas',
        'Bad Bunny anunció su gira mundial más ambiciosa hasta la fecha con 80 fechas en 5 continentes, incluyendo estadios en México, España, Japón y Australia. El artista puertorriqueño también reveló que lanzará un nuevo álbum como acompañamiento musical de la gira.',
        '/uploads/noticia_badbunny.jpg',
        'musica,badbunny,entretenimiento',
        20
    ),
    (
        'Tesla presenta el Robotaxi: transporte autónomo sin volante',
        'Elon Musk presentó oficialmente el Tesla Robotaxi, un vehículo totalmente autónomo sin volante ni pedales diseñado exclusivamente para servicios de transporte. Con un precio por kilómetro inferior al de un Uber convencional, Tesla planea desplegar una flota inicial de 10,000 unidades en 2027.',
        '/uploads/noticia_tesla_robotaxi.jpg',
        'tesla,tecnologia,autos',
        16
    ),
    (
        'Nintendo Switch 2 se agota en minutos en su preventa mundial',
        'La Nintendo Switch 2 se agotó en menos de 10 minutos durante su preventa global. La nueva consola híbrida cuenta con una pantalla OLED de 8 pulgadas, soporte para juegos en 4K cuando está conectada al dock, y retrocompatibilidad total con los juegos de Switch original.',
        '/uploads/noticia_switch2.jpg',
        'gaming,nintendo,switch',
        20
    )
]

with conn.cursor() as cur:
    # 1. Eliminar cualquier post de prueba restante
    cur.execute("""
        SELECT id_blog FROM blog 
        WHERE LOWER(titulo) LIKE '%prueba%' 
           OR LOWER(titulo) LIKE '%pruev%' 
           OR LOWER(titulo) LIKE '%pruba%'
           OR LOWER(`desc`) LIKE '%prueba%'
           OR LOWER(`desc`) LIKE '%pruev%'
           OR titulo = 'HOLA'
           OR titulo = 'NUEVO BLOG';
    """)
    ids_basura = [r[0] for r in cur.fetchall()]
    if ids_basura:
        fmt = ','.join(['%s'] * len(ids_basura))
        cur.execute(f"DELETE FROM comentarios WHERE blog_id IN ({fmt});", ids_basura)
        cur.execute(f"DELETE FROM valoraciones WHERE blog_id IN ({fmt});", ids_basura)
        cur.execute(f"DELETE FROM blog WHERE id_blog IN ({fmt});", ids_basura)
        print(f"Eliminados {len(ids_basura)} posts residuales de prueba.")

    # 2. Eliminar posts de noticias con interrogaciones si quedó alguno
    cur.execute("""
        SELECT id_blog FROM blog 
        WHERE titulo LIKE '%Verstappen%' 
           OR titulo LIKE '%NVIDIA%' 
           OR titulo LIKE '%Champions%'
           OR titulo LIKE '%Ryzen%'
           OR titulo LIKE '%Marte%'
           OR titulo LIKE '%GTA VI%'
           OR titulo LIKE '%ChatGPT%'
           OR titulo LIKE '%Am%rica%'
           OR titulo LIKE '%iPhone%'
           OR titulo LIKE '%Hamilton%'
           OR titulo LIKE '%Avatar%'
           OR titulo LIKE '%Python%'
           OR titulo LIKE '%Bad Bunny%'
           OR titulo LIKE '%Tesla%'
           OR titulo LIKE '%Nintendo%';
    """)
    ids_noticias_viejas = [r[0] for r in cur.fetchall()]
    if ids_noticias_viejas:
        fmt = ','.join(['%s'] * len(ids_noticias_viejas))
        cur.execute(f"DELETE FROM comentarios WHERE blog_id IN ({fmt});", ids_noticias_viejas)
        cur.execute(f"DELETE FROM valoraciones WHERE blog_id IN ({fmt});", ids_noticias_viejas)
        cur.execute(f"DELETE FROM blog WHERE id_blog IN ({fmt});", ids_noticias_viejas)
        print(f"Limpiados {len(ids_noticias_viejas)} posts de noticias viejas.")

    # 3. Insertar las 15 noticias limpias con utf8mb4
    sql_insert = "INSERT INTO blog (titulo, `desc`, img, tags, usr_id) VALUES (%s, %s, %s, %s, %s)"
    inserted_ids = []
    for noti in noticias:
        cur.execute(sql_insert, noti)
        inserted_ids.append(cur.lastrowid)

    print(f"Insertadas con éxito {len(inserted_ids)} noticias limpias.")

    # 4. Insertar comentarios asociados
    comentarios = [
        ('¡Increíble temporada de Verstappen, nadie puede con él!', 20, inserted_ids[0]),
        ('La RTX 5090 es una bestia, aunque el precio es bastante elevado.', 2, inserted_ids[1]),
        ('¡Hala Madrid! El gol de Vinícius fue espectacular.', 18, inserted_ids[2]),
        ('AMD sigue mejorando cada generación, competencia sana para Intel.', 5, inserted_ids[3]),
        ('Esto podría cambiar completamente la exploración espacial.', 6, inserted_ids[4]),
        ('Llevo años esperando GTA VI, ojalá no lo retrasen.', 14, inserted_ids[5]),
        ('La IA está cambiando el mundo más rápido de lo que imaginamos.', 2, inserted_ids[6]),
        ('¡Vamos América! El más grande de México.', 20, inserted_ids[7]),
        ('El diseño del iPhone 17 se ve increíble, muy delgado.', 16, inserted_ids[8]),
        ('Hamilton en Ferrari es un sueño hecho realidad para muchos fans.', 5, inserted_ids[9]),
    ]
    for c in comentarios:
        cur.execute("INSERT INTO comentarios (comentario, fecha, estatus, usr_id, blog_id) VALUES (%s, NOW(), 1, %s, %s)", c)

    conn.commit()
    print("Comentarios insertados y base de datos actualizada al 100%.")

conn.close()
