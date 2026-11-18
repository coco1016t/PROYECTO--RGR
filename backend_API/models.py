from sqlalchemy import (
    Column, Integer, String, Text,
    DateTime, ForeignKey, func,
    UniqueConstraint, CheckConstraint
)
from sqlalchemy.orm import relationship
from database import Base
class Usuario(Base):
    __tablename__ = "usuario"

    id_usr = Column(Integer, primary_key=True, index=True)
    nom_usr = Column(String(100), nullable=False)
    mail = Column(String(150), unique=True, nullable=False)
    pass_hash = Column("pass", String(255), nullable=False)
    dir_usr = Column(String(200), nullable=True)
    tip_usu = Column(Integer, nullable=False, default=1)


class TokenRecuperacion(Base):
    __tablename__ = "codigo_recuperacion"

    id = Column(Integer, primary_key=True, index=True)
    usr_id = Column(
        Integer,
        ForeignKey("usuario.id_usr", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    token_hash = Column("codigo_hash", String(64), nullable=False)
    expira_en = Column(Integer, nullable=False)
    creado_en = Column(Integer, nullable=False)
    intentos = Column(Integer, nullable=False, default=0)


class Blog(Base):
    __tablename__ = "blog"
    id_blog = Column(Integer, primary_key=True, index=True)
    titulo = Column(String(150), nullable=False)
    descripcion = Column("desc", Text, nullable=True)
    img = Column(String(500), nullable=True)
    tags = Column(String(255), nullable=True)
    # Autor de la publicación (RF002: posts propios y de otros usuarios)
    usr_id = Column(
        Integer,
        ForeignKey("usuario.id_usr", ondelete="SET NULL"),
        nullable=True,
    )
    usuario = relationship("Usuario")

    @property
    def autor(self):
        return self.usuario.nom_usr if self.usuario else None
class Comentario(Base):
    __tablename__ = "comentarios"
    id_com = Column(Integer, primary_key=True, index=True)
    comentario = Column(Text, nullable=False)
    fecha = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
    )
    estatus = Column(Integer, nullable=False, default=1)
    usr_id = Column(
        Integer,
        ForeignKey("usuario.id_usr"),
        nullable=False,
    )
    blog_id = Column(
        Integer,
        ForeignKey("blog.id_blog"),
        nullable=False,
    )
    usuario = relationship("Usuario")

    @property
    def autor(self):
        return self.usuario.nom_usr if self.usuario else None


class Valoracion(Base):
    __tablename__ = "valoraciones"
    __table_args__ = (
        # Un usuario solo puede tener una valoración por post.
        UniqueConstraint("usr_id", "blog_id", name="uq_valoracion_usr_blog"),
        CheckConstraint("puntos BETWEEN 1 AND 5", name="ck_valoracion_puntos"),
    )

    id_val = Column(Integer, primary_key=True, index=True)
    puntos = Column(Integer, nullable=False)
    fecha = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
        onupdate=func.current_timestamp(),
    )
    usr_id = Column(
        Integer,
        ForeignKey("usuario.id_usr", ondelete="CASCADE"),
        nullable=False,
    )
    blog_id = Column(
        Integer,
        ForeignKey("blog.id_blog", ondelete="CASCADE"),
        nullable=False,
    )