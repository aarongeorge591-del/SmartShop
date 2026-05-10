# SmartShopDB

This repository contains the database artefacts for the SmartShop Ltd.  
It is used for the CIS5004 **Practical Database Design and Implementation for SmartShop Ltd.** assessment.

## Structure

- `SQL/` – relational database scripts  
  - `SmartShopDB_Setup.sql` – schema creation & sample data  
  - `MonthlySales.sql`, `TopSellingProducts.sql` – report queries  
  - `TrasactionsTest.sql` – transaction/concurrency example  
  - `SQL_BI_Demo.sql` – combined analytical queries  

- `NoSQL/` – non‑relational examples  
  - `NoSQlSetup.js` – MongoDB shell script to create collections & sample documents  
  - `NoSQL_BI_Demo.js` – BI‑style aggregation queries in MongoDB  

## Usage

### Relational (SQL Server)
1. Open SQL Server Management Studio or use `sqlcmd`/`Invoke-Sqlcmd`.
2. Execute `SQL\SmartShopDB_Setup.sql` against a new database named `SmartShopDB`; this creates tables and inserts sample data.
3. Run `SQL\Transaction_Concurrency_Demo.sql` to walk through the transaction scenarios (basic order, race condition, isolation levels, deadlock); note that the monitoring section automatically adapts to older server versions by checking for DMV columns.
4. Analytical queries for BI are located in `SQL\SQL_BI_Demo.sql`, `MonthlySales.sql`, and `TopSellingProducts.sql` – you can copy these into Power BI's SQL Server source or run them directly in SSMS.

### Non‑relational (MongoDB)
1. Ensure the MongoDB service is running (`Get-Service MongoDB`).
2. From a shell, change directory to `NoSQL` and execute:
   ```powershell
   mongosh SmartShopNoSQL NoSQlSetup.js
   ```
   This drops any existing collections and inserts documents for branches, customers, products, orders (with embedded items), reviews and weblogs. The script also prints sample aggregation results.
3. To explore BI‑style aggregations use `NoSQL\NoSQL_BI_Demo.js` with `mongosh`.

### Business Intelligence
- Connect Power BI Desktop to the `SmartShopDB` SQL Server database; import the provided tables and invalidate default relationships, then create single‑direction links as described in the report (avoid bidirectional relationships to prevent ambiguity).
- Load the sample queries above or use the exported CSVs from MongoDB for hybrid analyses.

### Report and Submission
The assessment report should reference this repository, include screenshots of:
- SQL query outputs and Power BI visualisations (sales trends, category/bar chart, map by branch)
- Results of the NoSQL aggregations
It should also discuss ER design, normalization, transaction management, isolation levels, BI modelling, and the NoSQL/SQL comparison. Provide links and usage instructions within the PDF.

## Report guidance

The assessment report should reference this code, include screenshots of the outputs, and provide explanatory notes covering ER design, normalization, transactions, concurrency, BI visualisations and big‑data/NoSQL comparisons.

## Notes

- The ER diagram is available as Mermaid code within the report.
- Ensure you link to this repository and provide instructions in the submission PDF.
