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
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `product_id` int NOT NULL AUTO_INCREMENT,
  `product_name` varchar(100) NOT NULL,
  `quantity` int DEFAULT '0',
  `price` decimal(10,2) NOT NULL,
  `seller_port_id` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`product_id`),
  KEY `seller_port_id` (`seller_port_id`),
  CONSTRAINT `products_ibfk_1` FOREIGN KEY (`seller_port_id`) REFERENCES `seller_port` (`port_id`)
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES (1,'Plastic Sheets',50,59.50,'seller1'),(2,'Wooden Planks',30,120.00,'seller1'),(3,'Aluminum Rods',40,150.00,'seller1'),(4,'Steel Beams',20,200.00,'seller1'),(5,'Copper Wires',100,75.00,'seller1'),(6,'PVC Pipes',60,45.00,'seller1'),(7,'Glass Panels',25,180.00,'seller1'),(8,'Iron Nails',500,0.50,'seller1'),(9,'Concrete Bags',80,95.00,'seller1'),(10,'Ceramic Tiles',150,22.00,'seller1'),(11,'Brick Blocks',200,12.00,'seller1'),(12,'Paint Buckets',35,65.00,'seller1'),(13,'Adhesive Glue',45,25.00,'seller1'),(14,'Roofing Sheets',70,110.00,'seller1'),(15,'Insulation Rolls',55,85.00,'seller1'),(16,'Metal Screws',1000,0.10,'seller1'),(17,'Sand Bags',90,35.00,'seller1'),(18,'Timber Logs',15,250.00,'seller1'),(19,'Gravel Packs',120,20.00,'seller1'),(20,'Cement Blocks',160,15.00,'seller1'),(21,'Wire Mesh',40,60.00,'seller1'),(22,'Fiber Boards',50,70.00,'seller1'),(23,'MDF Sheets',45,55.00,'seller1'),(24,'Laminates',65,40.00,'seller1'),(25,'Vinyl Flooring',75,90.00,'seller1'),(26,'Rubber Sheets',80,35.00,'seller1'),(27,'Paint Brushes',200,5.00,'seller1'),(28,'Putty Powder',85,30.00,'seller1'),(29,'Sealant Tubes',95,18.00,'seller1'),(30,'Drywall Sheets',60,48.00,'seller1'),(31,'Stone Slabs',20,300.00,'seller1'),(32,'Plaster Bags',100,25.00,'seller1'),(33,'Concrete Blocks',130,16.00,'seller1'),(34,'Metal Pipes',50,110.00,'seller1'),(35,'Angle Irons',35,95.00,'seller1'),(36,'Channel Bars',40,105.00,'seller1'),(37,'Rebar Rods',70,80.00,'seller1'),(38,'Hex Nuts',500,0.15,'seller1'),(39,'Bolts',400,0.20,'seller1'),(40,'Washers',450,0.05,'seller1'),(41,'Power Tools',10,750.00,'seller1'),(42,'Hand Tools',20,250.00,'seller1'),(43,'Safety Helmets',30,45.00,'seller1'),(44,'Work Gloves',60,12.00,'seller1'),(45,'Measuring Tape',40,15.00,'seller1'),(46,'Toolboxes',25,80.00,'seller1'),(47,'Extension Cords',35,22.00,'seller1'),(48,'Electric Drills',15,550.00,'seller1'),(49,'Ladders',20,120.00,'seller1'),(50,'Wheelbarrows',10,95.00,'seller1'),(53,'Iron Pipes',100,99.99,'seller1'),(54,'ajay',1,100.00,'seller1'),(55,'oil',10,100.00,'ram'),(56,'bat',2,500.00,'ram');
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
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
