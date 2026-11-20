from sqlalchemy import (
    Column, Integer, String, Text,
    DateTime, ForeignKey, func,
    UniqueConstraint, CheckConstraint, Index, text,
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


class Conversacion(Base):
    __tablename__ = "conversaciones"
    __table_args__ = (
        UniqueConstraint(
            "usuario_a_id",
            "usuario_b_id",
            name="uq_conversacion_pareja",
        ),
        CheckConstraint(
            "usuario_a_id < usuario_b_id",
            name="ck_conversacion_orden",
        ),
        Index("ix_conversacion_usuario_a", "usuario_a_id"),
        Index("ix_conversacion_usuario_b", "usuario_b_id"),
        {
            "mysql_engine": "InnoDB",
            "mysql_charset": "utf8mb4",
            "mysql_collate": "utf8mb4_unicode_ci",
        },
    )

    id_conversacion = Column(Integer, primary_key=True, autoincrement=True)
    usuario_a_id = Column(
        Integer,
        ForeignKey(
            "usuario.id_usr",
            name="fk_conversacion_usuario_a",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    usuario_b_id = Column(
        Integer,
        ForeignKey(
            "usuario.id_usr",
            name="fk_conversacion_usuario_b",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    creada_en = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
    )

    usuario_a = relationship("Usuario", foreign_keys=[usuario_a_id])
    usuario_b = relationship("Usuario", foreign_keys=[usuario_b_id])
    mensajes = relationship(
        "Mensaje",
        back_populates="conversacion",
        cascade="all, delete-orphan",
        order_by="Mensaje.id_mensaje",
    )


class Mensaje(Base):
    __tablename__ = "mensajes"
    __table_args__ = (
        Index(
            "ix_mensaje_conversacion",
            "id_conversacion",
            "id_mensaje",
        ),
        Index(
            "ix_mensaje_no_leidos",
            "id_conversacion",
            "emisor_id",
            "leido_en",
        ),
        Index("ix_mensaje_emisor", "emisor_id"),
        {
            "mysql_engine": "InnoDB",
            "mysql_charset": "utf8mb4",
            "mysql_collate": "utf8mb4_unicode_ci",
        },
    )

    id_mensaje = Column(Integer, primary_key=True, autoincrement=True)
    id_conversacion = Column(
        Integer,
        ForeignKey(
            "conversaciones.id_conversacion",
            name="fk_mensaje_conversacion",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    emisor_id = Column(
        Integer,
        ForeignKey(
            "usuario.id_usr",
            name="fk_mensaje_emisor",
            ondelete="CASCADE",
        ),
        nullable=False,
    )
    contenido = Column(String(2000), nullable=False)
    fecha_envio = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
    )
    leido_en = Column(
        DateTime,
        nullable=True,
        server_default=text("NULL"),
    )

    conversacion = relationship("Conversacion", back_populates="mensajes")
    emisor = relationship("Usuario")
