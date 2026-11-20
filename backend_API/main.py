from pathlib import Path
import hmac
from uuid import uuid4
from contextlib import asynccontextmanager
from fastapi import (
    FastAPI,
    Depends,
    HTTPException,
    UploadFile,
    File,
    Form,
    Query,
    Response,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from sqlalchemy import and_, case, func, inspect, or_, select, update
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from pwdlib import PasswordHash
from database import Base, engine, obtener_sesion
from models import (
    Usuario,
    Blog,
    Comentario,
    Valoracion,
    Conversacion,
    Mensaje,
)
from schemas import (
    UsuarioCrear,
    UsuarioActualizar,
    UsuarioRespuesta,
    BlogRespuesta,
    ComentarioCrear,
    ComentarioRespuesta,
    LoginRequest,
    TokenRespuesta,
    ValoracionCrear,
    ValoracionResumen,
    ContactoMensajeriaRespuesta,
    ConversacionRespuesta,
    MensajeCrear,
    MensajeRespuesta,
    MensajesPaginaRespuesta,
    MensajesLeidosRespuesta,
)
from seguridad import crear_token, usuario_actual, usuario_opcional, solo_admin

password_hash = PasswordHash.recommended()
UPLOAD_DIR = Path(__file__).resolve().parent / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
MAX_IMAGE_SIZE = 10 * 1024 * 1024


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    if engine.dialect.name == "mysql":
        blog_columns = {
            column["name"] for column in inspect(engine).get_columns("blog")
        }
        if "usr_id" not in blog_columns:
            raise RuntimeError(
                "La base MySQL necesita la migracion de Paso 2; "
                "ejecuta backend_API/migracion_paso1_2.sql una sola vez."
            )
    yield

app = FastAPI(
    title="API de aplicación móvil",
    lifespan=lifespan,
)
app.mount(
    "/uploads",
    StaticFiles(directory=UPLOAD_DIR),
    name="uploads",
)


@app.get("/")
def inicio():
    return {"mensaje": "API funcionando correctamente"}
# Permitir la comunicación con Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:60450",
        "http://127.0.0.1:60450",
    ],
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------
# AUTENTICACIÓN (RF001)
# ---------------------------------------------------------------

@app.post("/login", response_model=TokenRespuesta)
def iniciar_sesion(
    datos: LoginRequest,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.mail.strip().lower()

    usuario = db.scalar(
        select(Usuario).where(Usuario.mail == correo)
    )

    # Se utiliza el mismo mensaje para no revelar
    # si el correo está registrado.
    try:
        password_valida = usuario is not None and password_hash.verify(
            datos.password,
            usuario.pass_hash,
        )
    except Exception:
        # Legacy SQL seeds may contain the literal HASH_DE_PRUEBA marker.
        password_valida = False

    # Keep accounts that still store their original plain-text password usable,
    # then upgrade that same password to Argon2 after a successful login.
    if (
        not password_valida
        and usuario is not None
        and usuario.pass_hash != "HASH_DE_PRUEBA"
        and not usuario.pass_hash.startswith("$")
        and hmac.compare_digest(datos.password, usuario.pass_hash)
    ):
        usuario.pass_hash = password_hash.hash(datos.password)
        db.commit()
        password_valida = True

    if not password_valida:
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos",
        )

    # Devuelve el token de sesión (JWT) junto con los datos públicos.
    return {
        "access_token": crear_token(usuario),
        "token_type": "bearer",
        "usuario": usuario,
    }

@app.post("/password-reset/update")
def actualizar_password(
    datos: LoginRequest,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.mail.strip().lower()
    nueva_password = datos.password

    if len(nueva_password) < 8:
        raise HTTPException(
            status_code=422,
            detail="La contraseña debe tener al menos 8 caracteres",
        )

    usuario = db.scalar(
        select(Usuario).where(Usuario.mail == correo)
    )

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="No existe una cuenta registrada con ese correo",
        )

    usuario.pass_hash = password_hash.hash(nueva_password)

    try:
        db.commit()
    except SQLAlchemyError:
        db.rollback()
        raise HTTPException(
            status_code=500,
            detail="No se pudo actualizar la contraseña",
        )

    return {"mensaje": "Contraseña actualizada correctamente"}
# ---------------------------------------------------------------
# USUARIOS
# ---------------------------------------------------------------

@app.get("/usuarios", response_model=list[UsuarioRespuesta])
def listar_usuarios(
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(solo_admin),
):
    return db.scalars(
        select(Usuario).order_by(Usuario.id_usr)
    ).all()


@app.post("/usuarios", response_model=UsuarioRespuesta, status_code=201)
def crear_usuario(
    datos: UsuarioCrear,
    db: Session = Depends(obtener_sesion),
    quien: Usuario | None = Depends(usuario_opcional),
):
    # El registro es público, pero solo un administrador autenticado
    # puede crear otro administrador. Cualquier otro caso queda como 2.
    tipo = datos.tip_usu if (quien is not None and quien.tip_usu == 1) else 2

    usuario = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=password_hash.hash(datos.password),
        dir_usr=datos.dir_usr,
        tip_usu=tipo,
    )

    db.add(usuario)

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return usuario
@app.put(
    "/usuarios/{usuario_id}",
    response_model=UsuarioRespuesta,
)
def actualizar_usuario(
    usuario_id: int,
    datos: UsuarioActualizar,
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    # Un usuario solo edita su propio perfil; el admin edita a cualquiera.
    if quien.tip_usu != 1 and quien.id_usr != usuario_id:
        raise HTTPException(
            status_code=403,
            detail="No puedes modificar a otro usuario",
        )

    usuario = db.get(Usuario, usuario_id)

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    usuario.nom_usr = datos.nom_usr.strip()
    usuario.mail = datos.mail.strip().lower()
    usuario.dir_usr = datos.dir_usr
    # Solo el administrador puede cambiar el tipo de usuario.
    if quien.tip_usu == 1:
        usuario.tip_usu = datos.tip_usu

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="El correo ya está registrado",
        )

    return usuario


@app.delete("/usuarios/{usuario_id}")
def eliminar_usuario(
    usuario_id: int,
    db: Session = Depends(obtener_sesion),
    _admin: Usuario = Depends(solo_admin),
):
    usuario = db.get(Usuario, usuario_id)

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    db.delete(usuario)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail=(
                "No se puede eliminar la cuenta porque tiene información "
                "relacionada que debe resolverse primero."
            ),
        ) from exc

    return {"mensaje": "Usuario eliminado correctamente"}


# ---------------------------------------------------------------
# MENSAJERÍA PRIVADA
# ---------------------------------------------------------------

def _previsualizar_mensaje(contenido: str) -> str:
    texto = " ".join(contenido.split())
    if len(texto) <= 80:
        return texto
    return f"{texto[:77].rstrip()}..."


def _buscar_conversacion(
    db: Session,
    usuario_a_id: int,
    usuario_b_id: int,
) -> Conversacion | None:
    return db.scalar(
        select(Conversacion).where(
            Conversacion.usuario_a_id == usuario_a_id,
            Conversacion.usuario_b_id == usuario_b_id,
        )
    )


def _conversacion_del_usuario(
    db: Session,
    conversacion_id: int,
    usuario_id: int,
) -> Conversacion:
    conversacion = db.scalar(
        select(Conversacion).where(
            Conversacion.id_conversacion == conversacion_id,
            or_(
                Conversacion.usuario_a_id == usuario_id,
                Conversacion.usuario_b_id == usuario_id,
            ),
        )
    )
    if conversacion is None:
        raise HTTPException(
            status_code=404,
            detail="Conversación no encontrada",
        )
    return conversacion


def _respuesta_conversacion(
    db: Session,
    conversacion: Conversacion,
    usuario_id: int,
) -> dict:
    contacto_id = (
        conversacion.usuario_b_id
        if conversacion.usuario_a_id == usuario_id
        else conversacion.usuario_a_id
    )
    contacto = db.get(Usuario, contacto_id)
    if contacto is None:
        raise HTTPException(
            status_code=404,
            detail="Contacto no encontrado",
        )

    ultimo = db.scalar(
        select(Mensaje)
        .where(Mensaje.id_conversacion == conversacion.id_conversacion)
        .order_by(Mensaje.id_mensaje.desc())
        .limit(1)
    )
    no_leidos = db.scalar(
        select(func.count(Mensaje.id_mensaje)).where(
            Mensaje.id_conversacion == conversacion.id_conversacion,
            Mensaje.emisor_id != usuario_id,
            Mensaje.leido_en.is_(None),
        )
    )

    return {
        "id_conversacion": conversacion.id_conversacion,
        "contacto": {
            "id_usr": contacto.id_usr,
            "nom_usr": contacto.nom_usr,
        },
        "ultimo_mensaje": (
            _previsualizar_mensaje(ultimo.contenido) if ultimo else None
        ),
        "fecha_ultimo_mensaje": ultimo.fecha_envio if ultimo else None,
        "no_leidos": int(no_leidos or 0),
    }


def _respuesta_mensaje(mensaje: Mensaje) -> dict:
    return {
        "id_mensaje": mensaje.id_mensaje,
        "id_conversacion": mensaje.id_conversacion,
        "emisor_id": mensaje.emisor_id,
        "contenido": mensaje.contenido,
        "fecha_envio": mensaje.fecha_envio,
    }


@app.get(
    "/mensajes/contactos",
    response_model=list[ContactoMensajeriaRespuesta],
)
def listar_contactos_mensajeria(
    buscar: str = Query(..., min_length=2, max_length=80),
    limite: int = Query(8, ge=1, le=20),
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    termino = buscar.strip()
    if len(termino) < 2:
        return []

    contactos = db.execute(
        select(Usuario.id_usr, Usuario.nom_usr)
        .where(
            Usuario.id_usr != quien.id_usr,
            Usuario.nom_usr.contains(termino, autoescape=True),
        )
        .order_by(Usuario.nom_usr, Usuario.id_usr)
        .limit(limite)
    ).all()
    return [
        {"id_usr": contacto.id_usr, "nom_usr": contacto.nom_usr}
        for contacto in contactos
    ]


@app.get(
    "/mensajes/conversaciones",
    response_model=list[ConversacionRespuesta],
)
def listar_conversaciones_mensajeria(
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    contacto_id = case(
        (
            Conversacion.usuario_a_id == quien.id_usr,
            Conversacion.usuario_b_id,
        ),
        else_=Conversacion.usuario_a_id,
    )
    filas_conversaciones = db.execute(
        select(
            Conversacion.id_conversacion.label("id_conversacion"),
            contacto_id.label("contacto_id"),
            Usuario.nom_usr.label("contacto_nombre"),
        )
        .join(Usuario, Usuario.id_usr == contacto_id)
        .where(
            or_(
                Conversacion.usuario_a_id == quien.id_usr,
                Conversacion.usuario_b_id == quien.id_usr,
            )
        )
    ).all()
    if not filas_conversaciones:
        return []

    ids_conversaciones = [
        fila.id_conversacion for fila in filas_conversaciones
    ]
    ultimos_ids = (
        select(
            Mensaje.id_conversacion.label("id_conversacion"),
            func.max(Mensaje.id_mensaje).label("ultimo_id"),
        )
        .where(Mensaje.id_conversacion.in_(ids_conversaciones))
        .group_by(Mensaje.id_conversacion)
        .subquery()
    )
    filas_ultimos = db.execute(
        select(
            Mensaje.id_conversacion,
            Mensaje.id_mensaje,
            Mensaje.contenido,
            Mensaje.fecha_envio,
        ).join(
            ultimos_ids,
            and_(
                Mensaje.id_conversacion == ultimos_ids.c.id_conversacion,
                Mensaje.id_mensaje == ultimos_ids.c.ultimo_id,
            ),
        )
    ).all()
    ultimo_por_conversacion = {
        fila.id_conversacion: fila for fila in filas_ultimos
    }
    filas_no_leidos = db.execute(
        select(
            Mensaje.id_conversacion,
            func.count(Mensaje.id_mensaje).label("total"),
        )
        .where(
            Mensaje.id_conversacion.in_(ids_conversaciones),
            Mensaje.emisor_id != quien.id_usr,
            Mensaje.leido_en.is_(None),
        )
        .group_by(Mensaje.id_conversacion)
    ).all()
    no_leidos_por_conversacion = {
        fila.id_conversacion: int(fila.total) for fila in filas_no_leidos
    }

    salida = []
    for fila in filas_conversaciones:
        ultimo = ultimo_por_conversacion.get(fila.id_conversacion)
        salida.append(
            {
                "id_conversacion": fila.id_conversacion,
                "contacto": {
                    "id_usr": fila.contacto_id,
                    "nom_usr": fila.contacto_nombre,
                },
                "ultimo_mensaje": (
                    _previsualizar_mensaje(ultimo.contenido)
                    if ultimo is not None
                    else None
                ),
                "fecha_ultimo_mensaje": (
                    ultimo.fecha_envio if ultimo is not None else None
                ),
                "no_leidos": no_leidos_por_conversacion.get(
                    fila.id_conversacion,
                    0,
                ),
                "_tiene_mensajes": ultimo is not None,
                "_orden_actividad": (
                    ultimo.id_mensaje
                    if ultimo is not None
                    else fila.id_conversacion
                ),
            }
        )

    salida.sort(
        key=lambda item: (
            item["_tiene_mensajes"],
            item["_orden_actividad"],
        ),
        reverse=True,
    )
    for item in salida:
        item.pop("_tiene_mensajes")
        item.pop("_orden_actividad")
    return salida


@app.post(
    "/mensajes/conversaciones/{usuario_id}",
    response_model=ConversacionRespuesta,
    status_code=201,
    responses={200: {"model": ConversacionRespuesta}},
)
def abrir_conversacion_mensajeria(
    usuario_id: int,
    response: Response,
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    if usuario_id == quien.id_usr:
        raise HTTPException(
            status_code=400,
            detail="No puedes abrir una conversación contigo mismo.",
        )

    if db.get(Usuario, usuario_id) is None:
        raise HTTPException(status_code=404, detail="Contacto no encontrado")

    usuario_a_id, usuario_b_id = sorted((quien.id_usr, usuario_id))
    conversacion = _buscar_conversacion(db, usuario_a_id, usuario_b_id)
    creada = False
    if conversacion is None:
        conversacion = Conversacion(
            usuario_a_id=usuario_a_id,
            usuario_b_id=usuario_b_id,
        )
        db.add(conversacion)
        try:
            db.commit()
            db.refresh(conversacion)
            creada = True
        except IntegrityError as exc:
            db.rollback()
            conversacion = _buscar_conversacion(
                db,
                usuario_a_id,
                usuario_b_id,
            )
            if conversacion is None:
                if db.get(Usuario, usuario_id) is None:
                    raise HTTPException(
                        status_code=404,
                        detail="Contacto no encontrado",
                    ) from exc
                raise HTTPException(
                    status_code=409,
                    detail="No se pudo abrir la conversación.",
                ) from exc

    response.status_code = 201 if creada else 200
    return _respuesta_conversacion(db, conversacion, quien.id_usr)


@app.get(
    "/mensajes/conversaciones/{conversacion_id}/mensajes",
    response_model=MensajesPaginaRespuesta,
)
def listar_mensajes_conversacion(
    conversacion_id: int,
    limite: int = Query(default=50, ge=1, le=100),
    antes_de_id: int | None = Query(default=None, gt=0),
    despues_de_id: int | None = Query(default=None, ge=0),
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    if antes_de_id is not None and despues_de_id is not None:
        raise HTTPException(
            status_code=422,
            detail="Usa antes_de_id o despues_de_id, pero no ambos.",
        )

    conversacion = _conversacion_del_usuario(
        db,
        conversacion_id,
        quien.id_usr,
    )
    cursor = antes_de_id if antes_de_id is not None else despues_de_id
    if cursor not in (None, 0):
        pertenece = db.scalar(
            select(Mensaje.id_mensaje).where(
                Mensaje.id_mensaje == cursor,
                Mensaje.id_conversacion == conversacion.id_conversacion,
            )
        )
        if pertenece is None:
            raise HTTPException(
                status_code=422,
                detail="El cursor no pertenece a esta conversación.",
            )

    hay_mas_anteriores = False
    hay_mas_nuevos = False
    if despues_de_id is not None:
        consulta = (
            select(Mensaje)
            .where(
                Mensaje.id_conversacion == conversacion.id_conversacion,
                Mensaje.id_mensaje > despues_de_id,
            )
            .order_by(Mensaje.id_mensaje.asc())
            .limit(limite + 1)
        )
        mensajes = list(db.scalars(consulta).all())
        hay_mas_nuevos = len(mensajes) > limite
        mensajes = mensajes[:limite]
    else:
        consulta = select(Mensaje).where(
            Mensaje.id_conversacion == conversacion.id_conversacion
        )
        if antes_de_id is not None:
            consulta = consulta.where(Mensaje.id_mensaje < antes_de_id)
        consulta = consulta.order_by(Mensaje.id_mensaje.desc()).limit(limite + 1)
        mensajes_desc = list(db.scalars(consulta).all())
        hay_mas_anteriores = len(mensajes_desc) > limite
        mensajes = list(reversed(mensajes_desc[:limite]))

    return {
        "mensajes": [_respuesta_mensaje(mensaje) for mensaje in mensajes],
        "hay_mas_anteriores": hay_mas_anteriores,
        "hay_mas_nuevos": hay_mas_nuevos,
    }


@app.post(
    "/mensajes/conversaciones/{conversacion_id}/mensajes",
    response_model=MensajeRespuesta,
    status_code=201,
)
def enviar_mensaje_conversacion(
    conversacion_id: int,
    datos: MensajeCrear,
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    conversacion = _conversacion_del_usuario(
        db,
        conversacion_id,
        quien.id_usr,
    )
    contenido = datos.contenido.strip()
    if not contenido:
        raise HTTPException(
            status_code=422,
            detail="El mensaje no puede estar vacío.",
        )

    mensaje = Mensaje(
        id_conversacion=conversacion.id_conversacion,
        emisor_id=quien.id_usr,
        contenido=contenido,
    )
    db.add(mensaje)
    try:
        db.commit()
        db.refresh(mensaje)
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="No se pudo guardar el mensaje.",
        ) from exc
    return _respuesta_mensaje(mensaje)


@app.post(
    "/mensajes/conversaciones/{conversacion_id}/leidos",
    response_model=MensajesLeidosRespuesta,
)
def marcar_mensajes_leidos(
    conversacion_id: int,
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    conversacion = _conversacion_del_usuario(
        db,
        conversacion_id,
        quien.id_usr,
    )
    resultado = db.execute(
        update(Mensaje)
        .where(
            Mensaje.id_conversacion == conversacion.id_conversacion,
            Mensaje.emisor_id != quien.id_usr,
            Mensaje.leido_en.is_(None),
        )
        .values(leido_en=func.current_timestamp())
    )
    db.commit()
    return {"actualizados": int(resultado.rowcount or 0)}


# ---------------------------------------------------------------
# BLOG (RF002)
# ---------------------------------------------------------------

def _adjuntar_valoraciones(db: Session, posts: list[Blog]) -> list[Blog]:
    """Agrega a cada post su promedio y total de valoraciones (1 sola consulta)."""
    ids = [p.id_blog for p in posts]
    datos: dict[int, tuple[float, int]] = {}

    if ids:
        filas = db.execute(
            select(
                Valoracion.blog_id,
                func.avg(Valoracion.puntos),
                func.count(Valoracion.id_val),
            )
            .where(Valoracion.blog_id.in_(ids))
            .group_by(Valoracion.blog_id)
        ).all()
        datos = {b: (float(a), int(c)) for b, a, c in filas}

    for p in posts:
        promedio, total = datos.get(p.id_blog, (0.0, 0))
        p.promedio = round(promedio, 2)
        p.total_valoraciones = total

    return posts


@app.get("/blog", response_model=list[BlogRespuesta])
def listar_blog(
    db: Session = Depends(obtener_sesion),
    _quien: Usuario = Depends(usuario_actual),
):
    posts = db.scalars(
        select(Blog).order_by(Blog.id_blog.desc())
    ).all()
    return _adjuntar_valoraciones(db, list(posts))


# IMPORTANTE: /blog/mios va antes de /blog/{blog_id}, si no FastAPI
# intentaría interpretar "mios" como un id.
@app.get("/blog/mios", response_model=list[BlogRespuesta])
def listar_mis_posts(
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    posts = db.scalars(
        select(Blog)
        .where(Blog.usr_id == quien.id_usr)
        .order_by(Blog.id_blog.desc())
    ).all()
    return _adjuntar_valoraciones(db, list(posts))


@app.post("/blog", response_model=BlogRespuesta, status_code=201)
async def crear_blog(
    titulo: str = Form(..., min_length=2, max_length=150),
    descripcion: str = Form(..., min_length=1),
    imagen: UploadFile = File(...),
    tags: str | None = Form(default=None, max_length=255),
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    titulo = titulo.strip()
    descripcion = descripcion.strip()
    if len(titulo) < 2:
        raise HTTPException(
            status_code=422,
            detail="El título debe tener al menos 2 caracteres",
        )
    if not descripcion:
        raise HTTPException(
            status_code=422,
            detail="La descripción no puede estar vacía",
        )

    extension = Path(imagen.filename or "").suffix.lower()
    if extension not in {".jpg", ".jpeg", ".png", ".webp"}:
        raise HTTPException(
            status_code=400,
            detail="Formato de imagen no permitido",
        )

    contenido = await imagen.read(MAX_IMAGE_SIZE + 1)
    if not contenido:
        raise HTTPException(status_code=400, detail="La imagen está vacía")
    if len(contenido) > MAX_IMAGE_SIZE:
        raise HTTPException(
            status_code=413,
            detail="La imagen supera el límite de 10 MB",
        )

    nombre_archivo = f"{uuid4().hex}{extension}"
    ruta_archivo = UPLOAD_DIR / nombre_archivo
    ruta_publica = f"/uploads/{nombre_archivo}"
    ruta_archivo.write_bytes(contenido)

    publicacion = Blog(
        titulo=titulo,
        descripcion=descripcion,
        img=ruta_publica,
        tags=tags.strip() if tags and tags.strip() else None,
        usr_id=quien.id_usr,  # el autor sale del token, no del cliente
    )

    db.add(publicacion)
    try:
        db.commit()
    except SQLAlchemyError as exc:
        db.rollback()
        ruta_archivo.unlink(missing_ok=True)
        raise HTTPException(
            status_code=500,
            detail="No se pudo guardar la publicación",
        ) from exc
    db.refresh(publicacion)

    return publicacion

@app.get("/blog/{blog_id}", response_model=BlogRespuesta)
def obtener_blog(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    _quien: Usuario = Depends(usuario_actual),
):
    publicacion = db.get(Blog, blog_id)

    if publicacion is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    return publicacion


# ---------------------------------------------------------------
# COMENTARIOS (RF003)
# ---------------------------------------------------------------

@app.get(
    "/blog/{blog_id}/comentarios",
    response_model=list[ComentarioRespuesta],
)
def listar_comentarios_de_post(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    _quien: Usuario = Depends(usuario_actual),
):
    if db.get(Blog, blog_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    return db.scalars(
        select(Comentario)
        .where(Comentario.blog_id == blog_id, Comentario.estatus == 1)
        .order_by(Comentario.id_com)
    ).all()


@app.post(
    "/comentarios",
    response_model=ComentarioRespuesta,
    status_code=201,
)
def crear_comentario(
    datos: ComentarioCrear,
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    texto = datos.comentario.strip()
    if not texto:
        raise HTTPException(
            status_code=422,
            detail="El comentario no puede estar vacío",
        )

    if db.get(Blog, datos.blog_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    nuevo = Comentario(
        comentario=texto,
        usr_id=quien.id_usr,  # el autor sale del token
        blog_id=datos.blog_id,
        estatus=1,
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo


# ---------------------------------------------------------------
# VALORACIÓN DE POSTS (RF005)
# ---------------------------------------------------------------

def _resumen_valoracion(db: Session, blog_id: int, usr_id: int) -> dict:
    """Promedio, total de votos y la puntuación del usuario con sesión."""
    promedio, total = db.execute(
        select(func.avg(Valoracion.puntos), func.count(Valoracion.id_val))
        .where(Valoracion.blog_id == blog_id)
    ).one()

    mia = db.scalar(
        select(Valoracion.puntos).where(
            Valoracion.blog_id == blog_id,
            Valoracion.usr_id == usr_id,
        )
    )

    return {
        "promedio": round(float(promedio), 2) if promedio is not None else 0.0,
        "total": int(total or 0),
        "mi_puntuacion": mia,
    }


@app.get(
    "/blog/{blog_id}/valoracion",
    response_model=ValoracionResumen,
)
def consultar_valoracion(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    if db.get(Blog, blog_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    return _resumen_valoracion(db, blog_id, quien.id_usr)


@app.put(
    "/blog/{blog_id}/valoracion",
    response_model=ValoracionResumen,
)
def valorar_blog(
    blog_id: int,
    datos: ValoracionCrear,
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    """Crea la valoración del usuario o la reemplaza si ya había votado."""
    if db.get(Blog, blog_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    existente = db.scalar(
        select(Valoracion).where(
            Valoracion.blog_id == blog_id,
            Valoracion.usr_id == quien.id_usr,
        )
    )

    if existente is None:
        db.add(
            Valoracion(
                puntos=datos.puntos,
                usr_id=quien.id_usr,  # el votante sale del token
                blog_id=blog_id,
            )
        )
    else:
        existente.puntos = datos.puntos

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="No se pudo registrar la valoración",
        )

    return _resumen_valoracion(db, blog_id, quien.id_usr)
