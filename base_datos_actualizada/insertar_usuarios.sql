-- ============================================================
-- Script para insertar todos los usuarios requeridos por el sistema
-- Ejecutar en MySQL/MariaDB sobre la base bd_aplicacion_movil
-- ============================================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET character_set_connection=utf8mb4;

USE bd_aplicacion_movil;

-- Inserta los usuarios asegurando los mismos IDs para mantener
-- la integridad referencial con los posts, comentarios y mensajes.
-- Si un usuario con el mismo ID o correo ya existe, se actualiza sin causar error.

INSERT INTO usuario (id_usr, nom_usr, mail, pass, dir_usr, tip_usu) VALUES
(1, 'andres', 'andres@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$0xrEs7scl0xhMn57n4ej5w$TnZzO0sJkdgQ0HzY9JrRsBlSLTk05xs70s4Qo3Ud4zc', 'Buenavista QRO', 1),
(2, 'reynaldo', 'reynaldo@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$uv/fn0c324wVKRKtbzRtXw$xvBK4ctWJese2Aib9S6laYcyFVuWUUtgfOIHk0MSjp8', 'QRO', 1),
(5, 'Andres', 'andresgonzalez@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$cnEvb6XFU+CVaHkR2HiixQ$xggX5DCWeZjbnzGD1/QQHKeFXwye8T1LsiT834FpvXY', 'UTTEQ', 2),
(6, 'Jose perez', 'uteq@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$GswWKbqQc2tDTKBUJsBKcA$Jm8d0Y/sbM2grkw7Ur0gVYHLycq9wgz+d8StY3l5jQo', 'uteq', 2),
(8, 'Jose perez', 'uteq1@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$JnssFWQW/uX3zC8CM6u3QA$Z6Nf3Rvyjye9if2LcsyP2YHR2e3MWKngVbXacldPujA', 'uteq', 2),
(14, 'Adriana Y Contreras Alvarez', 'adri@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$IasLlWhBshw6HSZKP6iGyQ$Tvk7eOt1tNfK1uWqOl2J0UeALvJ4S19HdoRG8wrZhxQ', 'Querétaro', 2),
(15, 'Andres Gonzalez Licea', 'andre@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$56D7g5J7YEpP3LAD6B5Fug$jv8o6gWScT1JfuBtUIUvYM4ukWtPd++O8j4YOQxZJxg', 'Santa Rosa', 1),
(16, 'rube azpeitia', 'rubas@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$JTatbbEB/Ss77PQ+nP4FJQ$dTvPxkH7G55cx4qYnU3uJBA1oZGyXJTJmQun3HVrlLg', 'Querétaro', 2),
(17, 'reynaldo Gonzalez', 'rey@uteq.edu.mx', '$argon2id$v=19$m=65536,t=3,p=4$y3YLwA/ocve742+x7bnfOA$1aoTKYkU77vCzpKk+2vPwodQE3DldjFBW1CiyG6fvyc', 'UTEQ', 1),
(18, 'gerardo', 'gerardo@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$M91n0DrC0ga63NNSl+ElLA$PTiFu4Pf0Zhe1WwZzzf49xX2S6r2Sn67Rzp7sjtM3JE', 'Querétaro', 2),
(20, 'luis', 'luis@gmail.com', '$argon2id$v=19$m=65536,t=3,p=4$nSJVHIVFU7SapunT3aospA$5a5Nnf8vSVvHPIUr5585U2QhbVWRK6CQgxBSBL92gtM', 'Querétaro', 2)
ON DUPLICATE KEY UPDATE
  nom_usr = VALUES(nom_usr),
  pass = VALUES(pass),
  dir_usr = VALUES(dir_usr),
  tip_usu = VALUES(tip_usu);

-- Ajustar el auto_increment para futuros registros
ALTER TABLE usuario AUTO_INCREMENT = 21;

SELECT '✅ Usuarios listos e insertados correctamente.' AS resultado;
