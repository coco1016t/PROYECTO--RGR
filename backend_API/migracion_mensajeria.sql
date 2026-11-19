-- Mensajería privada 1:1. Migración aditiva e idempotente.
-- Requiere MySQL 8.0.16+ o MariaDB 10.4+ para aplicar CHECK.
USE bd_aplicacion_movil;

CREATE TABLE IF NOT EXISTS conversaciones (
  id_conversacion INT NOT NULL AUTO_INCREMENT,
  usuario_a_id INT NOT NULL,
  usuario_b_id INT NOT NULL,
  creada_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_conversacion),
  UNIQUE KEY uq_conversacion_pareja (usuario_a_id, usuario_b_id),
  KEY ix_conversacion_usuario_a (usuario_a_id),
  KEY ix_conversacion_usuario_b (usuario_b_id),
  CONSTRAINT ck_conversacion_orden CHECK (usuario_a_id < usuario_b_id),
  CONSTRAINT fk_conversacion_usuario_a FOREIGN KEY (usuario_a_id)
    REFERENCES usuario (id_usr) ON DELETE CASCADE,
  CONSTRAINT fk_conversacion_usuario_b FOREIGN KEY (usuario_b_id)
    REFERENCES usuario (id_usr) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mensajes (
  id_mensaje INT NOT NULL AUTO_INCREMENT,
  id_conversacion INT NOT NULL,
  emisor_id INT NOT NULL,
  contenido VARCHAR(2000) NOT NULL,
  fecha_envio DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  leido_en DATETIME NULL DEFAULT NULL,
  PRIMARY KEY (id_mensaje),
  KEY ix_mensaje_conversacion (id_conversacion, id_mensaje),
  KEY ix_mensaje_no_leidos (id_conversacion, emisor_id, leido_en),
  KEY ix_mensaje_emisor (emisor_id),
  CONSTRAINT fk_mensaje_conversacion FOREIGN KEY (id_conversacion)
    REFERENCES conversaciones (id_conversacion) ON DELETE CASCADE,
  CONSTRAINT fk_mensaje_emisor FOREIGN KEY (emisor_id)
    REFERENCES usuario (id_usr) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
