from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class UsuarioCrear(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=8, max_length=128)
    dir_usr: str | None = None
    tip_usu: int = Field(default=2, ge=1, le=2)


class UsuarioRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    mail: str
    dir_usr: str | None
    tip_usu: int
    model_config = ConfigDict(from_attributes=True)

class UsuarioActualizar(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    dir_usr: str | None = None
    tip_usu: int = Field(default=1, ge=1, le=2)

class BlogCrear(BaseModel):
    titulo: str = Field(min_length=2, max_length=150)
    descripcion: str = Field(min_length=1)
    img: str | None = Field(default=None, max_length=500)
    tags: str | None = Field(default=None, max_length=255)

class BlogRespuesta(BaseModel):
    id_blog: int
    titulo: str
    descripcion: str | None = None
    img: str | None = None
    tags: str | None = None
    usr_id: int | None = None
    autor: str | None = None
    # Promedio de estrellas (RF005) para mostrarlo en la lista de posts
    promedio: float = 0.0
    total_valoraciones: int = 0
    model_config = ConfigDict(from_attributes=True)


class PerfilPublicoRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    publicaciones: list[BlogRespuesta]


class ComentarioCrear(BaseModel):
    # El autor (usr_id) ya no viaja en el body: se toma del token.
    comentario: str = Field(min_length=1, max_length=1000)
    blog_id: int


class ComentarioRespuesta(BaseModel):
    id_com: int
    comentario: str
    fecha: datetime
    estatus: int
    usr_id: int
    blog_id: int
    autor: str | None = None

    model_config = ConfigDict(from_attributes=True)
    
class LoginRequest(BaseModel):
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=1, max_length=128)


class TokenRespuesta(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioRespuesta


class ValoracionCrear(BaseModel):
    puntos: int = Field(ge=1, le=5)


class ValoracionResumen(BaseModel):
    promedio: float
    total: int
    mi_puntuacion: int | None = None


class ContactoMensajeriaRespuesta(BaseModel):
    id_usr: int
    nom_usr: str


class ConversacionRespuesta(BaseModel):
    id_conversacion: int
    contacto: ContactoMensajeriaRespuesta
    ultimo_mensaje: str | None = None
    fecha_ultimo_mensaje: datetime | None = None
    no_leidos: int


class MensajeCrear(BaseModel):
    contenido: str = Field(min_length=1, max_length=2000)


class MensajeRespuesta(BaseModel):
    id_mensaje: int
    id_conversacion: int
    emisor_id: int
    contenido: str
    fecha_envio: datetime


class MensajesPaginaRespuesta(BaseModel):
    mensajes: list[MensajeRespuesta]
    hay_mas_anteriores: bool = False
    hay_mas_nuevos: bool = False


class MensajesLeidosRespuesta(BaseModel):
    actualizados: int
