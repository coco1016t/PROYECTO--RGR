-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: bd_aplicacion_movil
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `bd_aplicacion_movil`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `bd_aplicacion_movil` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `bd_aplicacion_movil`;

--
-- Table structure for table `blog`
--

DROP TABLE IF EXISTS `blog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blog` (
  `id_blog` int(11) NOT NULL AUTO_INCREMENT,
  `titulo` varchar(150) NOT NULL,
  `desc` text DEFAULT NULL,
  `img` varchar(500) DEFAULT NULL,
  `tags` varchar(255) DEFAULT NULL,
  `usr_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id_blog`),
  KEY `fk_blog_usuario` (`usr_id`),
  CONSTRAINT `fk_blog_usuario` FOREIGN KEY (`usr_id`) REFERENCES `usuario` (`id_usr`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blog`
--

LOCK TABLES `blog` WRITE;
/*!40000 ALTER TABLE `blog` DISABLE KEYS */;
INSERT INTO `blog` VALUES (1,'Introduccion a MySQL','Conceptos basicos de bases de datos relacionales y MySQL.','mysql1.jpg','mysql,bd',1),(2,'Aprendiendo PHP','Primeros pasos para desarrollar aplicaciones web con PHP.','php1.jpg','php,web',1),(3,'HTML y CSS','Creacion de paginas web utilizando HTML y CSS.','htmlcss.jpg','html,css',1),(4,'JavaScript Basico','Uso de variables, funciones y eventos en JavaScript.','js.jpg','javascript,frontend',1),(5,'musica','playlist de musica para proyectarse.','img5.jpg','musica',1),(6,'prueba de que si funcional el metodo POST','Porfavor que si, se incerte en la base de datos','https://picsum.photos/800/400','tecnologia',1),(7,'Prueba para ver si se registra','si esta prueba se reggistra en la base de datos lloro',NULL,NULL,1),(8,'Este es la pruba para reggistro de un BLOG','Se guardara en la base de datos y se mostrara la tabla actualizada donde se reggistro este blog','flutter_application_7\\lib\\imagenes\\fondo.jpg','movil',1),(9,'NUEVO BLOG','ESTE SERA EL BLOG DE PRUEBA PARA EL VIDEO',NULL,'movil',1),(10,'HOLA','QUE SI FUNCIONE','/uploads/5da04e578744453cb8d2adac504bffce.jpg','Movil',1),(11,'HOLA','QUE SI FUNCIONE','/uploads/460ca9559a264cf0b73af1d9ca43d529.jpg','Movil',1),(12,'nuevo pokemon','Pruev para ver lo de la imagen','/uploads/ea8ef97bf4834ef8ac0a9b17ade26b30.jpg','tecnologia',1),(13,'Titulo prueba','prueba','/uploads/c4b5718f89404e5595c84555712cc4a5.jpg','tecnologia',1),(14,'Prueeva para captura de pantalla','si, sirve','/uploads/9aef690423a049a9b99754fd5915d448.jpg','pokemon',1),(15,'PRUEBA PARA LAA RESPUESTA DE LA API','RESPUESTA DE API A LA CARGA DE NA IMAGEN','/uploads/8bcea4d43b4843cbba397632a42f5879.jpg','MOVIL',1),(16,'prueba para el video 2','prueba por que la primera no me salio','/uploads/320c73b452104167a341d7b5951bb6b0.jpg','trecnologia',1);
/*!40000 ALTER TABLE `blog` ENABLE KEYS */;
UNLOCK TABLES;

-- Limpieza al reconstruir una base de versiones anteriores.
DROP TABLE IF EXISTS `codigo_recuperacion`;

--
-- Table structure for table `comentarios`
--

DROP TABLE IF EXISTS `comentarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comentarios` (
  `id_com` int(11) NOT NULL AUTO_INCREMENT,
  `comentario` text NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp(),
  `estatus` int(11) NOT NULL DEFAULT 1,
  `usr_id` int(11) NOT NULL,
  `blog_id` int(11) NOT NULL,
  PRIMARY KEY (`id_com`),
  KEY `fk_comentario_usuario` (`usr_id`),
  KEY `fk_comentario_blog` (`blog_id`),
  CONSTRAINT `fk_comentario_blog` FOREIGN KEY (`blog_id`) REFERENCES `blog` (`id_blog`),
  CONSTRAINT `fk_comentario_usuario` FOREIGN KEY (`usr_id`) REFERENCES `usuario` (`id_usr`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comentarios`
--

LOCK TABLES `comentarios` WRITE;
/*!40000 ALTER TABLE `comentarios` DISABLE KEYS */;
INSERT INTO `comentarios` VALUES (1,'excelente algo aburrido pero bueno.','2026-10-14 12:39:58',1,1,1),(2,'PHP es un lenguaje muy estresante para aplicaciones web.','2026-10-14 12:39:58',1,2,2),(3,'como que me estan ensenando css y HTML en blog de notas.','2026-10-14 12:39:58',1,1,3),(4,'Los ejemplos de JavaScript me ayudaron mucho.','2026-10-14 12:39:58',1,2,4),(5,'me encanta la musica para proyectarse.','2026-10-14 12:39:58',1,1,5);
/*!40000 ALTER TABLE `comentarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuario`
--

DROP TABLE IF EXISTS `usuario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usuario` (
  `id_usr` int(11) NOT NULL AUTO_INCREMENT,
  `nom_usr` varchar(100) NOT NULL,
  `mail` varchar(150) NOT NULL,
  `pass` varchar(255) NOT NULL,
  `dir_usr` varchar(200) DEFAULT NULL,
  `tip_usu` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_usr`),
  UNIQUE KEY `mail` (`mail`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuario`
--

LOCK TABLES `usuario` WRITE;
/*!40000 ALTER TABLE `usuario` DISABLE KEYS */;
INSERT INTO `usuario` VALUES (1,'andres','andres@gmail.com','123456','Buenavista QRO',1),(2,'reynaldo','reynaldo@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$uv/fn0c324wVKRKtbzRtXw$xvBK4ctWJese2Aib9S6laYcyFVuWUUtgfOIHk0MSjp8','QRO',1),(5,'Andres','andresgonzalez@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$cnEvb6XFU+CVaHkR2HiixQ$xggX5DCWeZjbnzGD1/QQHKeFXwye8T1LsiT834FpvXY','UTTEQ',2),(6,'Jose perez','uteq@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$GswWKbqQc2tDTKBUJsBKcA$Jm8d0Y/sbM2grkw7Ur0gVYHLycq9wgz+d8StY3l5jQo','uteq',2),(8,'Jose perez','uteq1@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$JnssFWQW/uX3zC8CM6u3QA$Z6Nf3Rvyjye9if2LcsyP2YHR2e3MWKngVbXacldPujA','uteq',2),(10,'string','string','$argon2id$v=19$m=65536,t=3,p=4$G+J4ymz3raY43xl+GIbOuQ$FRqmYkrnoDa7h0XPnZrmC9C8hkVnX0v2ojwWmvP/Y+Y','string',1),(11,'Prueba Login','prueba@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$P2SR0V3ShrEUro/HsU3StQ$NO2cPmhS0Y9IwF3nRiA+3tBox/pRID3rCbXEzG88/A0','QRO',1),(12,'Prueba Blog','blog@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$V9eAhACnPSkl5t03XB3nQw$puoAY7JAT8oysIn5/iEd701tAPSZqPf/clu43kF5eg0','QRO',2),(13,'registrobasededatos','usario@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$o/QzCK8sRR5M8mAA2VE+8w$FS5KExAYFGMxIA+R9JWIB/BEYaRlJ4ky1YSmP+U89wE','santarosa Jauregui',1),(14,'Adriana Y Contreras Alvarez','adri@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$IasLlWhBshw6HSZKP6iGyQ$Tvk7eOt1tNfK1uWqOl2J0UeALvJ4S19HdoRG8wrZhxQ',NULL,2),(15,'Andres Gozalez Licea','andre@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$56D7g5J7YEpP3LAD6B5Fug$jv8o6gWScT1JfuBtUIUvYM4ukWtPd++O8j4YOQxZJxg','Santa Rosa',1),(16,'rube azpeitia','rubas@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$JTatbbEB/Ss77PQ+nP4FJQ$dTvPxkH7G55cx4qYnU3uJBA1oZGyXJTJmQun3HVrlLg',NULL,2),(17,'reynaldo Gonzalez','rey@uteq.edu.mx','$argon2id$v=19$m=65536,t=3,p=4$y3YLwA/ocve742+x7bnfOA$1aoTKYkU77vCzpKk+2vPwodQE3DldjFBW1CiyG6fvyc',NULL,1),(18,'gerardo','gerardo@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$M91n0DrC0ga63NNSl+ElLA$PTiFu4Pf0Zhe1WwZzzf49xX2S6r2Sn67Rzp7sjtM3JE',NULL,2),(20,'luis','luis@gmail.com','$argon2id$v=19$m=65536,t=3,p=4$nSJVHIVFU7SapunT3aospA$5a5Nnf8vSVvHPIUr5585U2QhbVWRK6CQgxBSBL92gtM',NULL,2);
/*!40000 ALTER TABLE `usuario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `valoraciones`
--

DROP TABLE IF EXISTS `valoraciones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `valoraciones` (
  `id_val` int(11) NOT NULL AUTO_INCREMENT,
  `puntos` int(11) NOT NULL,
  `fecha` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `usr_id` int(11) NOT NULL,
  `blog_id` int(11) NOT NULL,
  PRIMARY KEY (`id_val`),
  UNIQUE KEY `uq_valoracion_usr_blog` (`usr_id`,`blog_id`),
  KEY `fk_valoracion_blog` (`blog_id`),
  CONSTRAINT `fk_valoracion_blog` FOREIGN KEY (`blog_id`) REFERENCES `blog` (`id_blog`) ON DELETE CASCADE,
  CONSTRAINT `fk_valoracion_usuario` FOREIGN KEY (`usr_id`) REFERENCES `usuario` (`id_usr`) ON DELETE CASCADE,
  CONSTRAINT `ck_valoracion_puntos` CHECK (`puntos` between 1 and 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `valoraciones`
--

LOCK TABLES `valoraciones` WRITE;
/*!40000 ALTER TABLE `valoraciones` DISABLE KEYS */;
/*!40000 ALTER TABLE `valoraciones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'bd_aplicacion_movil'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-18 22:52:24

-- Estructura de mensajeria; se omiten las conversaciones privadas.
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
