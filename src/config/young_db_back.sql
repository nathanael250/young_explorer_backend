-- MySQL dump 10.13  Distrib 9.6.0, for macos26.3 (arm64)
--
-- Host: localhost    Database: young_explorers
-- ------------------------------------------------------
-- Server version	9.6.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '3c81a188-3cca-11f1-aad0-d34af8fb0420:1-5732';

--
-- Table structure for table `booking_participants`
--

DROP TABLE IF EXISTS `booking_participants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `booking_participants` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `booking_id` bigint DEFAULT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `gender` varchar(20) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `passport_number` varchar(100) DEFAULT NULL,
  `nationality` varchar(100) DEFAULT NULL,
  `emergency_contact` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `booking_id` (`booking_id`),
  CONSTRAINT `booking_participants_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `booking_participants`
--

LOCK TABLES `booking_participants` WRITE;
/*!40000 ALTER TABLE `booking_participants` DISABLE KEYS */;
INSERT INTO `booking_participants` VALUES (1,1,'Aline','Mutesi','female','2002-04-12','P123456','Rwandan','+250788000000');
/*!40000 ALTER TABLE `booking_participants` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `bookings`
--

DROP TABLE IF EXISTS `bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bookings` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `booking_reference` varchar(100) DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `package_id` bigint DEFAULT NULL,
  `availability_id` bigint DEFAULT NULL,
  `total_people` int DEFAULT NULL,
  `total_amount` decimal(10,2) DEFAULT NULL,
  `booking_status` enum('pending','confirmed','cancelled','expired','completed') DEFAULT 'pending',
  `payment_status` enum('unpaid','partial','paid','refunded') DEFAULT 'unpaid',
  `booked_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `booking_reference` (`booking_reference`),
  KEY `user_id` (`user_id`),
  KEY `package_id` (`package_id`),
  KEY `availability_id` (`availability_id`),
  CONSTRAINT `bookings_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `bookings_ibfk_2` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`),
  CONSTRAINT `bookings_ibfk_3` FOREIGN KEY (`availability_id`) REFERENCES `package_availability` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bookings`
--

LOCK TABLES `bookings` WRITE;
/*!40000 ALTER TABLE `bookings` DISABLE KEYS */;
INSERT INTO `bookings` VALUES (1,'YE-1779723550102-489',2,1,1,2,900.00,'cancelled','paid','2026-05-25 15:39:10');
/*!40000 ALTER TABLE `bookings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `destinations`
--

DROP TABLE IF EXISTS `destinations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `destinations` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `province` varchar(100) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `short_description` text,
  `full_description` longtext,
  `best_time_to_visit` varchar(255) DEFAULT NULL,
  `entry_fee` decimal(10,2) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `main_image` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `destinations`
--

LOCK TABLES `destinations` WRITE;
/*!40000 ALTER TABLE `destinations` DISABLE KEYS */;
INSERT INTO `destinations` VALUES (1,'Kigali Genocide Memorial','kigali-genocide-memorial','Kigali','Gasabo','history','A memorial and learning center in Kigali.','A key destination for understanding Rwanda history.','All year',0.00,-1.93060000,30.06060000,NULL,'active','2026-05-25 15:08:32');
/*!40000 ALTER TABLE `destinations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `media_files`
--

DROP TABLE IF EXISTS `media_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `media_files` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `file_name` varchar(255) DEFAULT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `file_type` varchar(100) DEFAULT NULL,
  `uploaded_by` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `uploaded_by` (`uploaded_by`),
  CONSTRAINT `media_files_ibfk_1` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `media_files`
--

LOCK TABLES `media_files` WRITE;
/*!40000 ALTER TABLE `media_files` DISABLE KEYS */;
/*!40000 ALTER TABLE `media_files` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `messages` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `full_name` varchar(255) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `message` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
INSERT INTO `messages` VALUES (1,'Visitor Name','visitor@example.com','Tour inquiry','I want to know more about Young Explorers packages.','2026-05-25 15:48:06');
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `package_availability`
--

DROP TABLE IF EXISTS `package_availability`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `package_availability` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `package_id` bigint DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `total_seats` int DEFAULT NULL,
  `reserved_seats` int DEFAULT '0',
  `confirmed_seats` int DEFAULT '0',
  `remaining_seats` int GENERATED ALWAYS AS (((`total_seats` - `reserved_seats`) - `confirmed_seats`)) STORED,
  `status` enum('available','fully_booked','cancelled','closed') DEFAULT 'available',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `package_id` (`package_id`),
  CONSTRAINT `package_availability_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `package_availability`
--

LOCK TABLES `package_availability` WRITE;
/*!40000 ALTER TABLE `package_availability` DISABLE KEYS */;
INSERT INTO `package_availability` (`id`, `package_id`, `start_date`, `end_date`, `total_seats`, `reserved_seats`, `confirmed_seats`, `status`, `created_at`) VALUES (1,1,'2026-07-10','2026-07-15',20,0,0,'available','2026-05-25 15:32:50');
/*!40000 ALTER TABLE `package_availability` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `package_day_destinations`
--

DROP TABLE IF EXISTS `package_day_destinations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `package_day_destinations` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `package_day_id` bigint DEFAULT NULL,
  `destination_id` bigint DEFAULT NULL,
  `visit_order` int DEFAULT NULL,
  `activity_title` varchar(255) DEFAULT NULL,
  `activity_description` text,
  `arrival_time` time DEFAULT NULL,
  `departure_time` time DEFAULT NULL,
  `notes` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `package_day_id` (`package_day_id`),
  KEY `destination_id` (`destination_id`),
  CONSTRAINT `package_day_destinations_ibfk_1` FOREIGN KEY (`package_day_id`) REFERENCES `package_days` (`id`),
  CONSTRAINT `package_day_destinations_ibfk_2` FOREIGN KEY (`destination_id`) REFERENCES `destinations` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `package_day_destinations`
--

LOCK TABLES `package_day_destinations` WRITE;
/*!40000 ALTER TABLE `package_day_destinations` DISABLE KEYS */;
INSERT INTO `package_day_destinations` VALUES (1,1,1,1,'Memorial visit','Guided history session.','15:00:00','17:00:00','Respectful dress recommended.','2026-05-25 15:31:57');
/*!40000 ALTER TABLE `package_day_destinations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `package_days`
--

DROP TABLE IF EXISTS `package_days`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `package_days` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `package_id` bigint DEFAULT NULL,
  `day_number` int DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `summary` text,
  `accommodation` varchar(255) DEFAULT NULL,
  `meals` varchar(255) DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `package_id` (`package_id`),
  CONSTRAINT `package_days_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `package_days`
--

LOCK TABLES `package_days` WRITE;
/*!40000 ALTER TABLE `package_days` DISABLE KEYS */;
INSERT INTO `package_days` VALUES (1,1,1,'Arrival in Kigali','Airport pickup and city introduction.','Kigali hotel','Dinner','14:00:00','19:00:00','2026-05-25 15:27:55'),(2,1,2,'Day 2','',NULL,NULL,NULL,NULL,'2026-05-25 15:27:55'),(3,1,3,'Day 3','',NULL,NULL,NULL,NULL,'2026-05-25 15:27:55'),(4,1,4,'Day 4','',NULL,NULL,NULL,NULL,'2026-05-25 15:27:55'),(5,1,5,'Day 5','',NULL,NULL,NULL,NULL,'2026-05-25 15:27:55');
/*!40000 ALTER TABLE `package_days` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `package_durations`
--

DROP TABLE IF EXISTS `package_durations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `package_durations` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `title` varchar(100) DEFAULT NULL,
  `total_days` int DEFAULT NULL,
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `package_durations`
--

LOCK TABLES `package_durations` WRITE;
/*!40000 ALTER TABLE `package_durations` DISABLE KEYS */;
INSERT INTO `package_durations` VALUES (1,'3 Days',3,'active','2026-05-25 15:17:56'),(2,'5 Days',5,'active','2026-05-25 15:17:56'),(3,'7 Days',7,'active','2026-05-25 15:17:56'),(4,'14 Days',14,'active','2026-05-25 15:17:56');
/*!40000 ALTER TABLE `package_durations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `package_exclusions`
--

DROP TABLE IF EXISTS `package_exclusions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `package_exclusions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `package_id` bigint DEFAULT NULL,
  `item` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `package_id` (`package_id`),
  CONSTRAINT `package_exclusions_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `package_exclusions`
--

LOCK TABLES `package_exclusions` WRITE;
/*!40000 ALTER TABLE `package_exclusions` DISABLE KEYS */;
INSERT INTO `package_exclusions` VALUES (1,1,'Visa fees'),(2,1,'Personal shopping');
/*!40000 ALTER TABLE `package_exclusions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `package_inclusions`
--

DROP TABLE IF EXISTS `package_inclusions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `package_inclusions` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `package_id` bigint DEFAULT NULL,
  `item` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `package_id` (`package_id`),
  CONSTRAINT `package_inclusions_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `package_inclusions`
--

LOCK TABLES `package_inclusions` WRITE;
/*!40000 ALTER TABLE `package_inclusions` DISABLE KEYS */;
INSERT INTO `package_inclusions` VALUES (1,1,'Transport'),(2,1,'Meals'),(3,1,'Tour guide');
/*!40000 ALTER TABLE `package_inclusions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `package_not_allowed_items`
--

DROP TABLE IF EXISTS `package_not_allowed_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `package_not_allowed_items` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `package_id` bigint DEFAULT NULL,
  `item` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `package_id` (`package_id`),
  CONSTRAINT `package_not_allowed_items_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `package_not_allowed_items`
--

LOCK TABLES `package_not_allowed_items` WRITE;
/*!40000 ALTER TABLE `package_not_allowed_items` DISABLE KEYS */;
INSERT INTO `package_not_allowed_items` VALUES (1,1,'Weapons'),(2,1,'Drugs');
/*!40000 ALTER TABLE `package_not_allowed_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `package_required_items`
--

DROP TABLE IF EXISTS `package_required_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `package_required_items` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `package_id` bigint DEFAULT NULL,
  `item` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `package_id` (`package_id`),
  CONSTRAINT `package_required_items_ibfk_1` FOREIGN KEY (`package_id`) REFERENCES `packages` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `package_required_items`
--

LOCK TABLES `package_required_items` WRITE;
/*!40000 ALTER TABLE `package_required_items` DISABLE KEYS */;
INSERT INTO `package_required_items` VALUES (1,1,'Passport'),(2,1,'Jacket');
/*!40000 ALTER TABLE `package_required_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `packages`
--

DROP TABLE IF EXISTS `packages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `packages` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `short_description` text,
  `full_description` longtext,
  `price_per_person` decimal(10,2) DEFAULT '0.00',
  `currency` varchar(10) DEFAULT 'USD',
  `duration_id` bigint DEFAULT NULL,
  `main_image` varchar(255) DEFAULT NULL,
  `meeting_point` varchar(255) DEFAULT NULL,
  `emergency_contact` varchar(100) DEFAULT NULL,
  `age_range` varchar(100) DEFAULT NULL,
  `fitness_level` varchar(100) DEFAULT NULL,
  `cancellation_policy` text,
  `status` enum('draft','published','archived') DEFAULT 'draft',
  `created_by` bigint DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `duration_id` (`duration_id`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `packages_ibfk_1` FOREIGN KEY (`duration_id`) REFERENCES `package_durations` (`id`),
  CONSTRAINT `packages_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `packages`
--

LOCK TABLES `packages` WRITE;
/*!40000 ALTER TABLE `packages` DISABLE KEYS */;
INSERT INTO `packages` VALUES (1,'5-Day Rwanda Explorer','5-day-rwanda-explorer','Culture, history, and city highlights.','A youth-friendly Rwanda exploration package.',450.00,'USD',2,NULL,'Kigali International Airport','+250788222222','15-25','easy',NULL,'published',2,'2026-05-25 15:27:55');
/*!40000 ALTER TABLE `packages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `booking_id` bigint DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `payment_method` varchar(100) DEFAULT NULL,
  `transaction_reference` varchar(255) DEFAULT NULL,
  `payment_proof` varchar(255) DEFAULT NULL,
  `payment_status` enum('pending','verified','rejected') DEFAULT 'pending',
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `booking_id` (`booking_id`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
INSERT INTO `payments` VALUES (1,1,900.00,'bank_transfer','TXN-001','/uploads/manual-proof.jpg','verified','2026-05-25 15:43:45','2026-05-25 15:40:08'),(2,1,900.00,'bank_transfer','TXN-001','/uploads/manual-proof.jpg','pending',NULL,'2026-05-25 15:40:58');
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `role` enum('admin','explorer') DEFAULT 'explorer',
  `profile_image` varchar(255) DEFAULT NULL,
  `status` enum('active','inactive','blocked') DEFAULT 'active',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'niyo','Nathanael','nathan@gmail.com','+250781796824','$2a$10$PIToiZEUlC1/Lm3ATZSMyuryAFXPomZaUNjdHeukrL3frLJfzbV2q','explorer',NULL,'active','2026-05-25 14:07:43'),(2,'Admin','User','admin@gmail.com','+250781790900','$2a$10$OzJmTTLR1SEgo7CDv9ztweIKEUV29F6qU4vxcy5BcdWwOK00GKr5C','admin',NULL,'active','2026-05-25 14:20:40');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-25 20:50:23
