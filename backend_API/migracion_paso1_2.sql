-- Paso 2: agrega el autor a las publicaciones existentes.
-- Ejecutar una sola vez en bd_aplicacion_movil, antes de usar el backend.
-- Las contrasenas de usuario no se modifican.

USE bd_aplicacion_movil;

ALTER TABLE blog
  ADD COLUMN usr_id INT NULL AFTER tags,
  ADD CONSTRAINT fk_blog_usuario
      FOREIGN KEY (usr_id) REFERENCES usuario (id_usr)
      ON DELETE SET NULL;

-- Los posts previos no guardaban autor; se asignan al usuario id 1,
-- siguiendo la migracion incluida con el Paso 2.
UPDATE blog SET usr_id = 1 WHERE usr_id IS NULL;
