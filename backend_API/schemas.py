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
    model_config = ConfigDict(from_attributes=True)


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


class SolicitarRecuperacion(BaseModel):
    mail: str = Field(min_length=5, max_length=150)


class RestablecerPassword(BaseModel):
    correo: str = Field(min_length=5, max_length=150)
    token: str = Field(min_length=32, max_length=128)
    password: str = Field(min_length=8, max_length=128)


class TokenRespuesta(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioRespuesta
