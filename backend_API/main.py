from pathlib import Path
import hashlib
import hmac
from email.message import EmailMessage
import os
import secrets
import smtplib
import ssl
import time
from urllib.parse import urlsplit, urlunsplit
from uuid import uuid4
from pydantic import BaseModel
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from sqlalchemy import func, inspect, select
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from pwdlib import PasswordHash
from database import Base, engine, obtener_sesion
<<<<<<< HEAD
from models import Usuario, Blog, Comentario, TokenRecuperacion
=======
from models import Usuario, Blog, Comentario, Valoracion
>>>>>>> 0efd663229994848a3caf3d9b2e3b05b5ce1ccdc
from schemas import (
    UsuarioCrear,
    UsuarioActualizar,
    UsuarioRespuesta,
    BlogRespuesta,
    ComentarioCrear,
    ComentarioRespuesta,
    LoginRequest,
    TokenRespuesta,
<<<<<<< HEAD
    SolicitarRecuperacion,
    RestablecerPassword,
)
from seguridad import (
    crear_token,
    usuario_actual,
    usuario_opcional,
    solo_admin,
=======
    ValoracionCrear,
    ValoracionResumen,
>>>>>>> 0efd663229994848a3caf3d9b2e3b05b5ce1ccdc
)

password_hash = PasswordHash.recommended()
UPLOAD_DIR = Path(__file__).resolve().parent / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
MAX_IMAGE_SIZE = 10 * 1024 * 1024
TOKEN_RECUPERACION_TTL = 10 * 60
TOKEN_RECUPERACION_ESPERA = 60


def _configuracion_smtp() -> tuple[str, int, str, str, str, bool]:
    host = os.getenv("SMTP_HOST", "").strip()
    remitente = os.getenv("SMTP_FROM_EMAIL", "").strip()
    if not host or not remitente:
        raise HTTPException(
            status_code=503,
            detail="El envío de correo no está configurado en el servidor",
        )

    try:
        puerto = int(os.getenv("SMTP_PORT", "587"))
    except ValueError as exc:
        raise HTTPException(
            status_code=503,
            detail="La configuración SMTP del servidor no es válida",
        ) from exc

    usar_starttls = os.getenv("SMTP_STARTTLS", "true").strip().lower() == "true"
    return (
        host,
        puerto,
        os.getenv("SMTP_USERNAME", "").strip(),
        os.getenv("SMTP_PASSWORD", ""),
        remitente,
        usar_starttls,
    )


def _url_restablecimiento(token: str) -> str:
    url_base = os.getenv("PASSWORD_RESET_URL", "").strip()
    partes = urlsplit(url_base)
    ruta = partes.fragment.partition("?")[0] if partes.fragment else ""
    if (
        partes.scheme not in {"http", "https"}
        or not partes.netloc
        or ruta not in {"", "/reset-password"}
    ):
        raise HTTPException(
            status_code=503,
            detail="La URL de recuperación no está configurada correctamente",
        )

    fragmento = f"/reset-password?token={token}"
    return urlunsplit(
        (partes.scheme, partes.netloc, partes.path, partes.query, fragmento)
    )


def _enviar_enlace_recuperacion(correo: str, enlace: str) -> None:
    host, puerto, usuario, password, remitente, usar_starttls = _configuracion_smtp()
    mensaje = EmailMessage()
    mensaje["Subject"] = "Enlace para recuperar tu contraseña"
    mensaje["From"] = remitente
    mensaje["To"] = correo
    mensaje.set_content(
        "Abre este enlace para crear una nueva contraseña:\n\n"
        f"{enlace}\n\n"
        "El enlace vence en 10 minutos y solo se puede usar una vez. "
        "Si no solicitaste este cambio, puedes ignorar este mensaje."
    )

    contexto = ssl.create_default_context()
    try:
        with smtplib.SMTP(host, puerto, timeout=10) as servidor:
            if usar_starttls:
                servidor.starttls(context=contexto)
            if usuario:
                servidor.login(usuario, password)
            servidor.send_message(mensaje)
    except (OSError, smtplib.SMTPException) as exc:
        raise HTTPException(
            status_code=502,
            detail="No se pudo enviar el correo de recuperación",
        ) from exc


def _clave_token_recuperacion() -> bytes:
    clave = os.getenv("PASSWORD_RESET_SECRET", "").strip()
    if not clave:
        raise HTTPException(
            status_code=503,
            detail="La recuperación de contraseña no está configurada en el servidor",
        )
    return clave.encode("utf-8")


def _hash_token_recuperacion(token: str) -> str:
    return hmac.new(
        _clave_token_recuperacion(),
        token.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


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


@app.post("/password-reset/request")
def solicitar_recuperacion(
    datos: SolicitarRecuperacion,
    db: Session = Depends(obtener_sesion),
):
    _configuracion_smtp()
    _clave_token_recuperacion()
    _url_restablecimiento("validacion-configuracion")
    correo = datos.mail.strip().lower()
    usuario = db.scalar(select(Usuario).where(Usuario.mail == correo))
    if usuario is None:
        return {
            "mensaje": (
                "Si el correo está registrado, recibirás un enlace de recuperación"
            )
        }

    ahora = int(time.time())
    token_anterior = db.scalar(
        select(TokenRecuperacion)
        .where(TokenRecuperacion.usr_id == usuario.id_usr)
        .order_by(TokenRecuperacion.creado_en.desc())
        .with_for_update()
    )
    if (
        token_anterior is not None
        and ahora - token_anterior.creado_en < TOKEN_RECUPERACION_ESPERA
    ):
        return {
            "mensaje": (
                "Si el correo está registrado, recibirás un enlace de recuperación"
            )
        }

    token = secrets.token_urlsafe(32)
    if token_anterior is not None:
        db.delete(token_anterior)
    nuevo_token = TokenRecuperacion(
        usr_id=usuario.id_usr,
        token_hash=_hash_token_recuperacion(token),
        expira_en=ahora + TOKEN_RECUPERACION_TTL,
        creado_en=ahora,
    )
    db.add(nuevo_token)
    db.commit()

    try:
        _enviar_enlace_recuperacion(correo, _url_restablecimiento(token))
    except HTTPException:
        db.delete(nuevo_token)
        db.commit()
        raise

    return {
        "mensaje": (
            "Si el correo está registrado, recibirás un enlace de recuperación"
        )
    }


@app.post("/usuarios/restablecer-password")
def confirmar_recuperacion(
    datos: RestablecerPassword,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.correo.strip().lower()
    usuario = db.scalar(select(Usuario).where(Usuario.mail == correo))
    token = (
        db.scalar(
            select(TokenRecuperacion)
            .where(TokenRecuperacion.usr_id == usuario.id_usr)
            .order_by(TokenRecuperacion.creado_en.desc())
            .with_for_update()
        )
        if usuario is not None
        else None
    )
    ahora = int(time.time())
    if (
        token is None
        or token.expira_en <= ahora
    ):
        raise HTTPException(
            status_code=400,
            detail="El enlace es inválido o ha vencido",
        )

    if not hmac.compare_digest(
        token.token_hash,
        _hash_token_recuperacion(datos.token),
    ):
        raise HTTPException(
            status_code=400,
            detail="El enlace es inválido o ha vencido",
        )

    usuario.pass_hash = password_hash.hash(datos.password)
    db.delete(token)
    db.commit()
    return {"mensaje": "La contraseña se actualizó correctamente"}

class ActualizarPasswordRequest(BaseModel):
    mail: str
    password: str

@app.post("/password-reset/update")
def actualizar_password(
    datos: ActualizarPasswordRequest,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.mail.strip().lower()

    if len(datos.password) < 8:
        raise HTTPException(
            status_code=400,
            detail="La contraseña debe tener al menos 8 caracteres",
        )

    usuario = db.scalar(select(Usuario).where(Usuario.mail == correo))
    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Correo no registrado",
        )

    # UPDATE usuario SET pass = <hash argon2> WHERE mail = <correo>
    usuario.pass_hash = password_hash.hash(datos.password)
    db.commit()

    return {"mensaje": "La contraseña se actualizó correctamente"}

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
    db.commit()

    return {"mensaje": "Usuario eliminado correctamente"}


# ---------------------------------------------------------------
# BLOG (RF002)
# ---------------------------------------------------------------

@app.get("/blog", response_model=list[BlogRespuesta])
def listar_blog(
    db: Session = Depends(obtener_sesion),
    _quien: Usuario = Depends(usuario_actual),
):
    return db.scalars(
        select(Blog).order_by(Blog.id_blog.desc())
    ).all()


# IMPORTANTE: /blog/mios va antes de /blog/{blog_id}, si no FastAPI
# intentaría interpretar "mios" como un id.
@app.get("/blog/mios", response_model=list[BlogRespuesta])
def listar_mis_posts(
    db: Session = Depends(obtener_sesion),
    quien: Usuario = Depends(usuario_actual),
):
    return db.scalars(
        select(Blog)
        .where(Blog.usr_id == quien.id_usr)
        .order_by(Blog.id_blog.desc())
    ).all()


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

# VALORACIÓN DE POSTS 

def _resumen_valoracion(db: Session, blog_id: int, usr_id: int) -> dict:
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