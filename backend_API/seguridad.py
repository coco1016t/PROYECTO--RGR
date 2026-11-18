import os
from datetime import datetime, timedelta, timezone
from pathlib import Path

import jwt
from dotenv import load_dotenv
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from database import obtener_sesion
from models import Usuario

load_dotenv(Path(__file__).with_name(".env"))

# La clave se lee del archivo .env (nunca se sube a GitHub).
JWT_SECRET = os.getenv("JWT_SECRET") or (
    "dev-only-cambia-esta-clave-por-una-aleatoria-de-32-bytes"
)
JWT_ALGORITMO = "HS256"
JWT_HORAS = int(os.getenv("JWT_HORAS", "8"))

esquema_bearer = HTTPBearer(auto_error=False)


def crear_token(usuario: Usuario) -> str:
    """Genera un JWT firmado con el id del usuario y su expiración."""
    ahora = datetime.now(timezone.utc)
    carga = {
        "sub": str(usuario.id_usr),
        "tip": usuario.tip_usu,
        "iat": ahora,
        "exp": ahora + timedelta(hours=JWT_HORAS),
    }
    return jwt.encode(carga, JWT_SECRET, algorithm=JWT_ALGORITMO)


def _usuario_desde_token(token: str, db: Session) -> Usuario | None:
    try:
        carga = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITMO])
        id_usr = int(carga["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        return None
    # Se consulta la BD: si el usuario fue eliminado, el token deja de servir.
    return db.get(Usuario, id_usr)


def usuario_actual(
    credenciales: HTTPAuthorizationCredentials | None = Depends(esquema_bearer),
    db: Session = Depends(obtener_sesion),
) -> Usuario:
    """Exige sesión válida. Se usa como dependencia en los endpoints privados."""
    usuario = (
        _usuario_desde_token(credenciales.credentials, db)
        if credenciales
        else None
    )
    if usuario is None:
        raise HTTPException(
            status_code=401,
            detail="Sesión inválida o expirada",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return usuario


def usuario_opcional(
    credenciales: HTTPAuthorizationCredentials | None = Depends(esquema_bearer),
    db: Session = Depends(obtener_sesion),
) -> Usuario | None:
    """Devuelve el usuario si manda token válido; si no, None (sin error)."""
    if credenciales is None:
        return None
    return _usuario_desde_token(credenciales.credentials, db)


def solo_admin(usuario: Usuario = Depends(usuario_actual)) -> Usuario:
    """Control de acceso: solo tip_usu = 1 (administrador)."""
    if usuario.tip_usu != 1:
        raise HTTPException(status_code=403, detail="Acceso solo para administradores")
    return usuario
