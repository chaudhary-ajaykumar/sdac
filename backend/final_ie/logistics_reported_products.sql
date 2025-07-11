-- MySQL dump 10.13  Distrib 8.0.41, for Win64 (x86_64)
--
-- Host: localhost    Database: logistics
-- ------------------------------------------------------
-- Server version	9.0.1

USE merged_ie_db;

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `reported_products`
--

DROP TABLE IF EXISTS `reported_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reported_products` (
  `report_id` int NOT NULL AUTO_INCREMENT,
  `consumer_port_id` varchar(50) DEFAULT NULL,
  `seller_port_id` varchar(50) DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `issue_type` enum('Damage','Wrong Product','Delayed','Still Not Received','Missing') DEFAULT NULL,
  `status` enum('Pending','Resolved') DEFAULT 'Pending',
  `action_taken` enum('Replacement','Compensation','Resend') DEFAULT NULL,
  `report_date` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`report_id`),
  KEY `consumer_port_id` (`consumer_port_id`),
  KEY `product_id` (`product_id`),
  KEY `seller_port_id` (`seller_port_id`),
  CONSTRAINT `reported_products_ibfk_1` FOREIGN KEY (`consumer_port_id`) REFERENCES `consumer_port` (`port_id`),
  CONSTRAINT `reported_products_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`),
  CONSTRAINT `reported_products_ibfk_3` FOREIGN KEY (`seller_port_id`) REFERENCES `seller_port` (`port_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reported_products`
--

LOCK TABLES `reported_products` WRITE;
/*!40000 ALTER TABLE `reported_products` DISABLE KEYS */;
/*!40000 ALTER TABLE `reported_products` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-07-11 20:42:56
