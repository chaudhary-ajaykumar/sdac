# sdac

### ✅ README.txt

`
# Project Name: MERGED_IE

## 🔧 Java Version
- Java SE 21
- Ensure JDK 21 is installed and configured in Eclipse:
  - Window → Preferences → Java → Installed JREs

## 🚀 Server Configuration
- Server: Apache Tomcat v11.0
- Required to run this project inside Eclipse
- Steps to configure:
  1. Open Eclipse
  2. Go to the 'Servers' tab
  3. Add New Server → Apache → Tomcat v11.0
  4. Set the Tomcat installation directory (e.g., `C:\Program Files\Apache Software Foundation\Tomcat 11.0`)

## ⚙ Build Tool
- This is a standard **Dynamic Web Project**
- Not using Maven or Ant
- Import via: `File → Import → Existing Projects into Workspace`

## 🗃 Database Configuration (MySQL)

### 📁 SQL Dump Folder
- Folder: `final_ie/`
- Contains 5 `.sql` files:
  - consumer_port.sql
  - orders.sql
  - products.sql
  - reported_products.sql
  - seller_port.sql

### ✅ Schema to Import Into:
- `merged_ie_db` (you already created this)

### ✅ All SQL files updated to:
sql
USE merged_ie_db;
`

This ensures correct schema usage during import.

### 🔁 To Import the Database:

1. Open MySQL Workbench
2. Go to: Server → Data Import
3. Select: `Import from Dump Project Folder`
4. Choose folder: `final_ie/`
5. Select or create schema: `merged_ie_db`
6. Select all tables listed (ensure all 5 are checked)
7. Click: `Start Import`
8. After completion: Right-click schema → Refresh → Tables should appear

---

## 💾 Database Connection in Code

Check this file:


src/main/java/com/yourpackage/DBConnection.java


Make sure the values are:

java
String url = "jdbc:mysql://localhost:3306/merged_ie_db";
String user = "root";
String password = "your_password";


---

## 📚 Libraries

* All required `.jar` files included in:

  
  WebContent/WEB-INF/lib/
  

  Includes:

  * `servlet-api.jar`
  * Any custom libraries you used

---

## ▶ How to Run

1. Open Eclipse
2. Import the project
3. Configure Tomcat 11 and JDK 21
4. Configure your DB connection
5. Right-click project → Run As → Run on Server

---

## 👨‍💻 Developer

* Name: chaudhary ajaykumar
* Project Date: 10/7/25


