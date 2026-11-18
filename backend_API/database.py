import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import DeclarativeBase, sessionmaker

load_dotenv(Path(__file__).with_name(".env"))

# MySQL is the project's default database. DATABASE_URL can override it, while
# DB_* variables keep compatibility with the original project configuration.
database_url = os.getenv("DATABASE_URL")
if database_url:
    url = database_url
else:
    url = URL.create(
        drivername="mysql+pymysql",
        username=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", "andres04"),
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        database=os.getenv("DB_NAME", "bd_aplicacion_movil"),
        query={"charset": "utf8mb4"},
    )

connect_args = {"check_same_thread": False} if str(url).startswith("sqlite") else {}
engine = create_engine(url, pool_pre_ping=True, connect_args=connect_args)
SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    pass


def obtener_sesion():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
