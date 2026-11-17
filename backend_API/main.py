from pathlib import Path
from uuid import uuid4
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from pwdlib import PasswordHash
from database import Base, engine, obtener_sesion
from models import Usuario, Blog, Comentario
from schemas import (
    UsuarioCrear,
    UsuarioActualizar,
    UsuarioRespuesta,
    BlogRespuesta,
    ComentarioCrear,
    ComentarioRespuesta,
    LoginRequest,
)

password_hash = PasswordHash.recommended()
UPLOAD_DIR = Path(__file__).resolve().parent / "uploads"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
MAX_IMAGE_SIZE = 10 * 1024 * 1024


@asynccontextmanager
async def lifespan(app: FastAPI):
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


@app.post("/login", response_model=UsuarioRespuesta)
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
    if usuario is None or not password_hash.verify(
        datos.password,
        usuario.pass_hash,
    ):
        raise HTTPException(
            status_code=401,
            detail="Correo o contraseña incorrectos",
        )

    # Devuelve únicamente los datos públicos del usuario.
    return usuario

# Conserva debajo todos tus endpoints existentes:
# @app.get("/usuarios")
# @app.post("/usuarios")
# etc.

# USUARIOS

@app.get("/usuarios", response_model=list[UsuarioRespuesta])
def listar_usuarios(db: Session = Depends(obtener_sesion)):
    return db.scalars(
        select(Usuario).order_by(Usuario.id_usr)
    ).all()


@app.post("/usuarios", response_model=UsuarioRespuesta, status_code=201)
def crear_usuario(
    datos: UsuarioCrear,
    db: Session = Depends(obtener_sesion),
):
    usuario = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=datos.mail.strip().lower(),
        pass_hash=password_hash.hash(datos.password),
        dir_usr=datos.dir_usr,
        tip_usu=datos.tip_usu,
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
):
    usuario = db.get(Usuario, usuario_id)

    if usuario is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    usuario.nom_usr = datos.nom_usr.strip()
    usuario.mail = datos.mail.strip().lower()
    usuario.dir_usr = datos.dir_usr
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

# BLOG

@app.get("/blog", response_model=list[BlogRespuesta])
def listar_blog(db: Session = Depends(obtener_sesion)):
    return db.scalars(
        select(Blog).order_by(Blog.id_blog)
    ).all()


@app.post("/blog", response_model=BlogRespuesta, status_code=201)
async def crear_blog(
    titulo: str = Form(..., min_length=2, max_length=150),
    descripcion: str = Form(..., min_length=1),
    imagen: UploadFile = File(...),
    tags: str | None = Form(default=None, max_length=255),
    db: Session = Depends(obtener_sesion),
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

@app.post("/blog/{blog_id}", response_model=BlogRespuesta)
def obtener_blog(
    blog_id: int,
    db: Session = Depends(obtener_sesion),
):
    publicacion = db.get(Blog, blog_id)

    if publicacion is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    return publicacion


# COMENTARIOS

@app.get(
    "/comentarios",
    response_model=list[ComentarioRespuesta],
)
def listar_comentarios(db: Session = Depends(obtener_sesion)):
    return db.scalars(
        select(Comentario).order_by(Comentario.id_com)
    ).all()


@app.post(
    "/comentarios",
    response_model=ComentarioRespuesta,
    status_code=201,
)
def crear_comentario(
    datos: ComentarioCrear,
    db: Session = Depends(obtener_sesion),
):
    if not datos.comentario.strip():
        raise HTTPException(
            status_code=422,
            detail="El comentario no puede estar vacío",
        )

    if db.get(Usuario, datos.usr_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Usuario no encontrado",
        )

    if db.get(Blog, datos.blog_id) is None:
        raise HTTPException(
            status_code=404,
            detail="Publicación no encontrada",
        )

    nuevo = Comentario(
        comentario=datos.comentario.strip(),
        usr_id=datos.usr_id,
        blog_id=datos.blog_id,
        estatus=1,
    )

    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    return nuevo