-- ## desc all_sequences

CREATE TABLE employees_afsar (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    email VARCHAR2(100),
    phone_number VARCHAR2(20),
    hire_date DATE,
    job_id VARCHAR2(10),
    salary NUMBER(8, 2),
    manager_id NUMBER,
    department_id NUMBER
);

select * from employees_afsar;
SELECT employee_id FROM employees ORDER BY employee_id;
CREATE SEQUENCE emp_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

INSERT INTO employees_afsar (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, manager_id, department_id)
VALUES (emp_seq.NEXTVAL, 'afsar', 'Aalam', 'afsar@example.com', '+911234567895', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 'IT_PROG', 45000.00, 100, 20);

INSERT INTO employees_afsar (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, manager_id, department_id)
VALUES (emp_seq.NEXTVAL, 'hackbugs', 'Aalam', 'afsar@example.com', '+911234567895', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 'IT_PROG', 45000.00, 100, 20);

INSERT INTO employees_afsar (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, manager_id, department_id)
VALUES (emp_seq.NEXTVAL, 'elfin', 'Aalam', 'afsar@example.com', '+911234567895', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 'IT_PROG', 45000.00, 100, 20);

INSERT INTO employees_afsar (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, manager_id, department_id)
VALUES (emp_seq.NEXTVAL, 'ruler', 'Aalam', 'afsar@example.com', '+911234567895', TO_DATE('2023-01-01', 'YYYY-MM-DD'), 'IT_PROG', 45000.00, 100, 20);

-- Generate and insert 50 random users records PL/SQL procedure in "employees_afsar" table
BEGIN
  FOR i IN 1..50 LOOP
    INSERT INTO employees_afsar (employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, manager_id, department_id)
    VALUES (emp_seq.NEXTVAL,
            'First'||LPAD(i, 2, '0'), -- Concatenate 'First' with a two-digit number (e.g., First01, First02, etc.) for first_name
            'Last'||LPAD(i, 2, '0'),  -- Concatenate 'Last' with a two-digit number (e.g., Last01, Last02, etc.) for last_name
            'user'||i||'@example.com', -- Concatenate 'user' with the loop index and '@example.com' for email
            '+91'||LPAD(dbms_random.value(1000000000, 9999999999), 10, '0'), -- Random 10-digit phone number prefixed with '+91'
            TO_DATE('2023-01-01', 'YYYY-MM-DD') + dbms_random.value(1, 365), -- Random hire_date within 1 year from 2023-01-01
            'IT_PROG', -- Fixed job_id
            ROUND(dbms_random.value(30000, 80000), 2), -- Random salary between 30000 and 80000
            100, -- Fixed manager_id
            20); -- Fixed department_id
  END LOOP;
  COMMIT; -- Commit the transaction
END;
/

--if only i created a table ther have not data than use this code to isert data in table
ALTER TABLE employees_afsar ADD (employee_id NUMBER PRIMARY KEY);
ALTER TABLE employees_afsar ADD (first_name VARCHAR2(50));
ALTER TABLE employees_afsar ADD (last_name VARCHAR2(50));
ALTER TABLE employees_afsar ADD (email VARCHAR2(100));
ALTER TABLE employees_afsar ADD (phone_number VARCHAR2(20));
ALTER TABLE employees_afsar ADD (hire_date DATE);
ALTER TABLE employees_afsar ADD (job_id VARCHAR2(10));
ALTER TABLE employees_afsar ADD (salary NUMBER(8, 2));
ALTER TABLE employees_afsar ADD (manager_id NUMBER);
ALTER TABLE employees_afsar ADD (department_id NUMBER);
ALTER TABLE employees_afsar ADD (password VARCHAR2(50));

-- use update cmd
UPDATE employees_afsar
SET phone_number = '+9161664204'
WHERE first_name = 'afsar' AND last_name = 'Aalam' AND phone_number = '+911234567895';
commit

-- create datafile and tablespace 
CREATE TABLESPACE users07 
DATAFILE 'users07.dbf' 
SIZE 100M 
AUTOEXTEND ON 
NEXT 10M 
MAXSIZE UNLIMITED;

-- retrive all tablespace name
SELECT tablespace_name FROM dba_tablespaces;
 
-- check information of PDBS
show pdbs;
SELECT CDB FROM V$DATABASE;
SELECT name FROM v$pdbs;
SELECT pdb_name, status FROM dba_pdbs;

ALTER SESSION SET CONTAINER = PDB$SEED;
ALTER PLUGGABLE DATABASE PDB$SEED CLOSE IMMEDIATE;
ALTER PLUGGABLE DATABASE PDB$SEED OPEN READ WRITE;
ALTER SESSION SET CONTAINER = PDB$SEED;

SELECT sys_context('USERENV', 'CON_NAME') AS current_pdb_name FROM dual;
SELECT name AS current_pdb_name FROM v$database;


--In Oracle Database, when you create a user with a name prefixed by C##, such as C##USERNAME,
--it denotes a "Common User" or "Container Database (CDB) User". This prefix was introduced to 
--differentiate between common users and local users within a multitenant architecture.

-- create user and assign on that tablespce which i created on top
CREATE USER C##user07 IDENTIFIED BY password
DEFAULT TABLESPACE users07
TEMPORARY TABLESPACE temp
QUOTA UNLIMITED ON users;

-- check all privileges
SELECT COUNT(*) AS total_privileges
FROM DBA_SYS_PRIVS;

-- find the user which i creted in which table space assign
SELECT username, default_tablespace, temporary_tablespace
FROM dba_users
WHERE username = 'C##USER07';

-- count how many table have contain in SYS user
SELECT COUNT(*) AS table_count
FROM dba_tables
WHERE owner = 'SYS';

-- count total DBA users
select count(*) as total_users
from dba_users

-- count total DBA tables
select count(*) as total_tables
from dba_tables

-- resize of datafiles
example  - ALTER DATABASE DATAFILE 'path_to_datafile' RESIZE new_size;
ALTER DATABASE DATAFILE '/u01/app/oracle/oradata/ORCL/users01.dbf' RESIZE 200M;

-- datafile loaction and tablespace details 

SELECT file_name,
       tablespace_name,
       bytes / 1024 / 1024 AS size_mb,
       (bytes - NVL(free_space, 0)) / 1024 / 1024 AS used_mb,
       NVL(free_space, 0) / 1024 / 1024 AS free_mb
  FROM (SELECT file_id,
               file_name,
               tablespace_name,
               bytes,
               (SELECT SUM(bytes)
                  FROM dba_free_space
                 WHERE file_id = df.file_id) AS free_space
          FROM dba_data_files df)
ORDER BY tablespace_name, file_name;

-- check tablespces details in MB total size, used size, free size, and used in persentage

SELECT tablespace_name,
       status,
       total_size_mb,
       used_size_mb,
       (total_size_mb - used_size_mb) AS free_size_mb,
       ROUND((used_size_mb / total_size_mb) * 100, 2) AS used_percent
  FROM (
        SELECT df.tablespace_name,
               'ONLINE' AS status,
               ROUND(SUM(df.bytes) / 1024 / 1024, 2) AS total_size_mb,
               ROUND(SUM(df.bytes) / 1024 / 1024, 2) - ROUND(NVL(SUM(fs.bytes), 0) / 1024 / 1024, 2) AS used_size_mb
          FROM dba_data_files df
          LEFT JOIN dba_free_space fs
            ON df.tablespace_name = fs.tablespace_name
         GROUP BY df.tablespace_name
        UNION ALL
        SELECT tf.tablespace_name,
               'ONLINE' AS status,
               ROUND(SUM(tf.bytes) / 1024 / 1024, 2) AS total_size_mb,
               ROUND(SUM(tf.bytes) / 1024 / 1024, 2) - ROUND(NVL(SUM(fst.bytes), 0) / 1024 / 1024, 2) AS used_size_mb
          FROM dba_temp_files tf
          LEFT JOIN dba_free_space fst
            ON tf.tablespace_name = fst.tablespace_name
         GROUP BY tf.tablespace_name
      )
ORDER BY tablespace_name;

-- check tablespace details in GB

SELECT tablespace_name,
       ROUND(SUM(bytes) / 1024 / 1024 / 1024, 2) AS total_size_gb,
       ROUND(SUM(bytes - NVL(free_space, 0)) / 1024 / 1024 / 1024, 2) AS used_size_gb,
       ROUND(SUM(NVL(free_space, 0)) / 1024 / 1024 / 1024, 2) AS free_space_gb,
       ROUND((SUM(bytes - NVL(free_space, 0)) / SUM(bytes)) * 100, 2) AS used_percent
  FROM (
        SELECT tablespace_name,
               bytes,
               0 AS free_space
          FROM dba_data_files
        UNION ALL
        SELECT tablespace_name,
               bytes,
               bytes AS free_space
          FROM dba_free_space
        UNION ALL
        SELECT tablespace_name,
               bytes,
               0 AS free_space
          FROM dba_temp_files
      )
GROUP BY tablespace_name
ORDER BY tablespace_name;


-- To find out how many users have objects in each tablespace

SELECT ts.tablespace_name,
       COUNT(DISTINCT u.username) AS user_count
  FROM dba_users u
  JOIN dba_segments s
    ON u.username = s.owner
  JOIN dba_tablespaces ts
    ON s.tablespace_name = ts.tablespace_name
 GROUP BY ts.tablespace_name
 ORDER BY ts.tablespace_name;

-- check tablespces and total size, used size, free size, and used in persentage, user count as well

WITH tablespace_usage AS (
  SELECT tablespace_name,
         status,
         total_size_mb,
         used_size_mb,
         (total_size_mb - used_size_mb) AS free_size_mb,
         ROUND((used_size_mb / total_size_mb) * 100, 2) AS used_percent
    FROM (
          SELECT df.tablespace_name,
                 'ONLINE' AS status,
                 ROUND(SUM(df.bytes) / 1024 / 1024, 2) AS total_size_mb,
                 ROUND(SUM(df.bytes) / 1024 / 1024, 2) - ROUND(NVL(SUM(fs.bytes), 0) / 1024 / 1024, 2) AS used_size_mb
            FROM dba_data_files df
            LEFT JOIN dba_free_space fs
              ON df.tablespace_name = fs.tablespace_name
           GROUP BY df.tablespace_name
          UNION ALL
          SELECT tf.tablespace_name,
                 'ONLINE' AS status,
                 ROUND(SUM(tf.bytes) / 1024 / 1024, 2) AS total_size_mb,
                 ROUND(SUM(tf.bytes) / 1024 / 1024, 2) - ROUND(NVL(SUM(fst.bytes), 0) / 1024 / 1024, 2) AS used_size_mb
            FROM dba_temp_files tf
            LEFT JOIN dba_free_space fst
              ON tf.tablespace_name = fst.tablespace_name
           GROUP BY tf.tablespace_name
        )
),
tablespace_users AS (
  SELECT ts.tablespace_name,
         COUNT(DISTINCT u.username) AS user_count
    FROM dba_users u
    JOIN dba_segments s
      ON u.username = s.owner
    JOIN dba_tablespaces ts
      ON s.tablespace_name = ts.tablespace_name
   GROUP BY ts.tablespace_name
)
SELECT tu.tablespace_name,
       tu.status,
       tu.total_size_mb,
       tu.used_size_mb,
       tu.free_size_mb,
       tu.used_percent,
       NVL(tu2.user_count, 0) AS user_count
  FROM tablespace_usage tu
  LEFT JOIN tablespace_users tu2
    ON tu.tablespace_name = tu2.tablespace_name
 ORDER BY tu.tablespace_name;

-- check tablespces and total size, used size, free size, and used in persentage, user count, datafile count

WITH tablespace_usage AS (
  SELECT tablespace_name,
         status,
         total_size_mb,
         used_size_mb,
         (total_size_mb - used_size_mb) AS free_size_mb,
         ROUND((used_size_mb / total_size_mb) * 100, 2) AS used_percent,
         datafile_count
    FROM (
          SELECT df.tablespace_name,
                 'ONLINE' AS status,
                 ROUND(SUM(df.bytes) / 1024 / 1024, 2) AS total_size_mb,
                 ROUND(SUM(df.bytes) / 1024 / 1024, 2) - ROUND(NVL(SUM(fs.bytes), 0) / 1024 / 1024, 2) AS used_size_mb,
                 COUNT(df.file_id) AS datafile_count
            FROM dba_data_files df
            LEFT JOIN dba_free_space fs
              ON df.tablespace_name = fs.tablespace_name
           GROUP BY df.tablespace_name
          UNION ALL
          SELECT tf.tablespace_name,
                 'ONLINE' AS status,
                 ROUND(SUM(tf.bytes) / 1024 / 1024, 2) AS total_size_mb,
                 ROUND(SUM(tf.bytes) / 1024 / 1024, 2) - ROUND(NVL(SUM(fst.bytes), 0) / 1024 / 1024, 2) AS used_size_mb,
                 COUNT(tf.file_id) AS datafile_count
            FROM dba_temp_files tf
            LEFT JOIN dba_free_space fst
              ON tf.tablespace_name = fst.tablespace_name
           GROUP BY tf.tablespace_name
        )
),
tablespace_users AS (
  SELECT ts.tablespace_name,
         COUNT(DISTINCT u.username) AS user_count
    FROM dba_users u
    JOIN dba_segments s
      ON u.username = s.owner
    JOIN dba_tablespaces ts
      ON s.tablespace_name = ts.tablespace_name
   GROUP BY ts.tablespace_name
)
SELECT tu.tablespace_name,
       tu.status,
       tu.total_size_mb,
       tu.used_size_mb,
       tu.free_size_mb,
       tu.used_percent,
       tu.datafile_count,
       NVL(tu2.user_count, 0) AS user_count
  FROM tablespace_usage tu
  LEFT JOIN tablespace_users tu2
    ON tu.tablespace_name = tu2.tablespace_name
 ORDER BY tu.tablespace_name;
 
--------------------------------------------------------------------------------------------------

SELECT member FROM v$logfile;
desc v$sgainfo;
select name, BYTES, RESIZEABLE,CON_ID from v$sgainfo

-----------------------------------------------------------------------------
 Give the grand and PRIVILEGES of user base on role an resposbilities
---------------------------------------------------------------------
GRANT CONNECT, RESOURCE TO new_schema;
GRANT CREATE TABLE TO new_schema;
GRANT CREATE VIEW TO new_schema;
GRANT CREATE PROCEDURE TO new_schema;
GRANT CREATE SEQUENCE TO new_schema;

GRANT CONNECT, RESOURCE, CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE SEQUENCE TO new_schema;

GRANT ALL PRIVILEGES TO new_schema;
GRANT DBA TO new_schema;
REVOKE ALL PRIVILEGES FROM new_schema;

FROM dba_sys_privs
FROM dba_tab_privs
FROM dba_role_privs
FROM dba_users;

SELECT grantee, privilege 
FROM dba_sys_privs 
WHERE grantee = 'USERNAME';

SELECT * FROM DBA_SYS_PRIVS;
SELECT * FROM DBA_TAB_PRIVS;
SELECT * FROM DBA_ROLE_PRIVS;

SELECT * FROM dba_ts_quotas WHERE username = 'new_schema';

SELECT grantee, owner, table_name, privilege 
FROM dba_tab_privs 
WHERE grantee = 'new_schema';

SELECT grantee, privilege 
FROM dba_sys_privs;

SELECT username, default_tablespace, temporary_tablespace
FROM dba_users
WHERE username = 'NEW_SCHEMA1';

SELECT username FROM dba_users WHERE username = 'NEW_SCHEMA'; 

ALTER SESSION SET CONTAINER = PDB$SEED;

GRANT CREATE TABLE TO new_schema;
ALTER USER new_schema QUOTA UNLIMITED ON users;

show user;


SELECT name, open_mode FROM v$database;

CREATE DATABASE CDB1
USER SYS IDENTIFIED BY oracle
USER SYSTEM IDENTIFIED BY oracle
ENABLE PLUGGABLE DATABASE;

SELECT name, open_mode FROM v$database;
select name,CON_ID,open_mode from v$pdbs;
desc v$pdbs;
show pdbs;
show user;
desc v$tablespace;

Datafiles
-------------
SELECT tablespace_name, file_name
FROM dba_data_files;

tablespaces
------------
SELECT tablespace_name, status, contents, logging, block_size
FROM dba_tablespaces;

SELECT file#, name, status
FROM v$datafile;

find all important loaction of oracle database
---------------------------------------------------
 Connect to the database as SYSDBA
 ---------------------------------------
sqlplus sys as sysdba

 Find control file locations
 ---------------------------------------
SELECT name FROM v$controlfile;

 Find redo log file locations
 ---------------------------------------
SELECT member FROM v$logfile;

 Find all tablespaces
 ---------------------------------------
SELECT tablespace_name FROM dba_tablespaces;

 Find datafile locations for tablespaces
 -----------------------------------------
SELECT tablespace_name, file_name FROM dba_data_files;

 Find temporary tablespace file locations
 --------------------------------------------
SELECT tablespace_name, file_name FROM dba_temp_files;

 Find archive log file locations
 ---------------------------------------
SELECT name FROM v$archived_log;

 Find shared pool and other SGA information
 --------------------------------------------
SELECT * FROM v$sga;

 Connect to the database as SYSDBA
 ---------------------------------------
sqlplus sys as sysdba

 Get information about the shared pool
 ---------------------------------------
SELECT * FROM v$sgastat WHERE pool = 'shared pool';

 Get information about the Java pool
 ---------------------------------------
SELECT * FROM v$sgastat WHERE pool = 'java pool';

 Get information about the large pool
 ---------------------------------------
SELECT * FROM v$sgastat WHERE pool = 'large pool';

 Get information about the streams pool
 ---------------------------------------
SELECT * FROM v$sgastat WHERE pool = 'streams pool';

 Get overall SGA information
 ---------------------------------------
SELECT * FROM v$sga;

 Get detailed SGA component information
SELECT * FROM v$sgainfo;

select * from v$sgastat where pool ='java pool';

SELECT status FROM v$instance;
shutdown immediate;
startup mount;
ALTER PLUGGABLE DATABASE pdb_name OPEN;

@ C:\Oracle\WINDOWS.X64_193000_db_home\rdbms\xml\schema\db-sample-schemas-21.1\human_resources\hr_main.sql

 PDBS conncet and conncet wtih schema means users;

# Connect to the CDB as SYSDBA
---------------------------------------
sqlplus sys as sysdba

# Switch to the PDB `pdbtest`
---------------------------------------
ALTER SESSION SET CONTAINER = pdbtest;

# Change the password for the user `hr`
-----------------------------------------
ALTER USER hr IDENTIFIED BY new_password;

# Verify the password change by connecting as `hr` with the new password
----------------------------------------------------------------------------
CONNECT hr/new_password@pdbtest;

------------------------------------------

Sure, here's a list of some common courses/topics typically covered in SQL and Oracle training:

1. SQL Basics
2. Data Manipulation Language (DML)
3. Data Definition Language (DDL)
4. Data Query Language (DQL)
5. Joins and Subqueries
6. Indexes and Views
7. Transactions and Locking
8. Constraints and Triggers
9. Stored Procedures and Functions
10. Performance Tuning
11. Data Warehousing Concepts
12. Backup and Recovery
13. Oracle Database Architecture
14. PL/SQL Programming
15. Oracle SQL Developer Tools
16. Advanced SQL Techniques

----------------------------------------------

Certainly! Here's a list of common types of functions used in SQL, which are typically supported across various relational database management systems (RDBMS):

### Types of SQL Functions

1. **Aggregate Functions**
   - Perform calculations on sets of values and return a single value.
   - Examples:
     - `COUNT()`: Returns the number of rows that match a specified condition.
     - `SUM()`: Returns the sum of values in a column.
     - `AVG()`: Returns the average value of a numeric column.
     - `MIN()`: Returns the minimum value in a set.
     - `MAX()`: Returns the maximum value in a set.

2. **Scalar Functions**
   - Operate on a single value and return a single value.
   - Examples:
     - `UPPER()`, `LOWER()`: Converts a string to uppercase or lowercase.
     - `LEN()`, `LENGTH()`: Returns the length of a string.
     - `CONCAT()`: Concatenates two or more strings.
     - `SUBSTRING()`, `SUBSTR()`: Extracts a substring from a string.
     - `ROUND()`, `TRUNC()`: Rounds or truncates a numeric value.

3. **String Functions**
   - Manipulate string data.
   - Examples:
     - `LEFT()`, `RIGHT()`: Extracts a specified number of characters from the start or end of a string.
     - `LTRIM()`, `RTRIM()`, `TRIM()`: Removes leading or trailing spaces from a string.
     - `REPLACE()`: Replaces occurrences of a substring within a string.
     - `CHAR_LENGTH()`, `CHARACTER_LENGTH()`: Returns the number of characters in a string.

4. **Numeric Functions**
   - Operate on numeric data types.
   - Examples:
     - `ABS()`: Returns the absolute value of a number.
     - `CEILING()`, `FLOOR()`: Rounds a number up or down to the nearest integer.
     - `POWER()`, `SQRT()`: Calculates the power or square root of a number.
     - `RAND()`, `ROUND()`: Generates a random number or rounds a number to a specified number of decimal places.

5. **Date and Time Functions**
   - Manipulate date and time values.
   - Examples:
     - `NOW()`, `CURRENT_TIMESTAMP()`: Returns the current date and time.
     - `DATE()`, `TIME()`: Extracts the date or time part from a datetime value.
     - `DATEADD()`, `DATEDIFF()`: Adds or subtracts a specified time interval from a date.
     - `DAYOFWEEK()`, `MONTH()`, `YEAR()`: Extracts components of a date.

6. **Conversion Functions**
   - Convert data types from one type to another.
   - Examples:
     - `CAST()`, `CONVERT()`: Converts a value from one data type to another.
     - `TO_CHAR()`, `TO_DATE()`, `TO_NUMBER()`: Converts strings to dates or numbers in Oracle SQL.

7. **Conditional Functions**
   - Perform conditional logic.
   - Examples:
     - `CASE`: Evaluates a list of conditions and returns one of multiple possible results.
     - `COALESCE()`: Returns the first non-null value in a list of expressions.
     - `IF()`, `IFNULL()`: Returns one value if a condition is true and another value if the condition is false.

8. **System Functions**
   - Provide information about the database or environment.
   - Examples:
     - `DATABASE()`, `USER()`: Returns the current database or user.
     - `VERSION()`: Returns the version of the database server.
     - `SESSION_USER()`: Returns the current session user.

9. **User-Defined Functions (UDFs)**
   - Created by users to perform specific tasks.
   - Examples:
     - Scalar UDFs: Operate on a single row and return a single value.
     - Table-Valued UDFs: Return a table result set.

Each SQL function type serves specific purposes and is used to perform various operations on data within SQL queries.
The syntax and availability of these functions may vary slightly between different database management systems. 
If you have specific questions or need examples for any function type, feel free to ask!

----------------------------------------------

Certainly! Here's a comprehensive list of SQL clauses commonly used in database querying and management:

### List of SQL Clauses

1. **SELECT**
   - Retrieves data from one or more tables.
   - Example:
     ```sql
     SELECT column1, column2 FROM table_name;
     ```

2. **FROM**
   - Specifies the tables from which to retrieve data in a `SELECT` statement.
   - Example:
     ```sql
     SELECT column1, column2 FROM table_name1, table_name2;
     ```

3. **WHERE**
   - Filters rows based on specified conditions.
   - Example:
     ```sql
     SELECT column1, column2 FROM table_name WHERE condition;
     ```

4. **GROUP BY**
   - Groups rows that have the same values into summary rows.
   - Example:
     ```sql
     SELECT COUNT(*), column1 FROM table_name GROUP BY column1;
     ```

5. **HAVING**
   - Filters groups based on specified conditions.
   - Example:
     ```sql
     SELECT column1, COUNT(*) FROM table_name GROUP BY column1 HAVING COUNT(*) > 1;
     ```

6. **ORDER BY**
   - Sorts the result set in ascending or descending order.
   - Example:
     ```sql
     SELECT column1, column2 FROM table_name ORDER BY column1 ASC;
     ```

7. **LIMIT**
   - Specifies the maximum number of rows to return from a query.
   - Example:
     ```sql
     SELECT column1, column2 FROM table_name LIMIT 10;
     ```

8. **OFFSET**
   - Skips the specified number of rows before returning the result set.
   - Example:
     ```sql
     SELECT column1, column2 FROM table_name LIMIT 10 OFFSET 5;
     ```

9. **INSERT INTO**
   - Adds new rows of data into a table.
   - Example:
     ```sql
     INSERT INTO table_name (column1, column2) VALUES (value1, value2);
     ```

10. **UPDATE**
    - Modifies existing records in a table.
    - Example:
      ```sql
      UPDATE table_name SET column1 = value1 WHERE condition;
      ```

11. **DELETE**
    - Removes existing records from a table.
    - Example:
      ```sql
      DELETE FROM table_name WHERE condition;
      ```

12. **JOIN**
    - Retrieves data from multiple tables based on a related column between them.
    - Example:
      ```sql
      SELECT column1, column2 FROM table1 INNER JOIN table2 ON table1.column = table2.column;
      ```

13. **INNER JOIN**
    - Retrieves rows that have matching values in both tables.
    - Example:
      ```sql
      SELECT * FROM table1 INNER JOIN table2 ON table1.column = table2.column;
      ```

14. **LEFT JOIN**
    - Retrieves all rows from the left table and matching rows from the right table.
    - Example:
      ```sql
      SELECT * FROM table1 LEFT JOIN table2 ON table1.column = table2.column;
      ```

15. **RIGHT JOIN**
    - Retrieves all rows from the right table and matching rows from the left table.
    - Example:
      ```sql
      SELECT * FROM table1 RIGHT JOIN table2 ON table1.column = table2.column;
      ```

16. **FULL OUTER JOIN**
    - Retrieves all rows from both tables and matches rows where possible.
    - Example:
      ```sql
      SELECT * FROM table1 FULL OUTER JOIN table2 ON table1.column = table2.column;
      ```

17. **UNION**
    - Combines the result sets of two or more `SELECT` statements into a single result set.
    - Example:
      ```sql
      SELECT column1 FROM table1 UNION SELECT column2 FROM table2;
      ```

18. **UNION ALL**
    - Combines the result sets of two or more `SELECT` statements into a single result set, including duplicates.
    - Example:
      ```sql
      SELECT column1 FROM table1 UNION ALL SELECT column2 FROM table2;
      ```

19. **DISTINCT**
    - Returns unique values from a column or expression in a `SELECT` statement.
    - Example:
      ```sql
      SELECT DISTINCT column1 FROM table_name;
      ```

20. **LIKE**
    - Searches for a specified pattern in a column.
    - Example:
      ```sql
      SELECT column1 FROM table_name WHERE column1 LIKE 'pattern%';
      ```

21. **IN**
    - Specifies multiple values for a `WHERE` clause.
    - Example:
      ```sql
      SELECT column1 FROM table_name WHERE column1 IN (value1, value2, ...);
      ```

22. **BETWEEN**
    - Specifies a range to search for in a `WHERE` clause.
    - Example:
      ```sql
      SELECT column1 FROM table_name WHERE column1 BETWEEN value1 AND value2;
      ```

23. **IS NULL**
    - Tests for empty values (NULL) in a `WHERE` clause.
    - Example:
      ```sql
      SELECT column1 FROM table_name WHERE column1 IS NULL;
      ```

24. **IS NOT NULL**
    - Tests for non-empty values (not NULL) in a `WHERE` clause.
    - Example:
      ```sql
      SELECT column1 FROM table_name WHERE column1 IS NOT NULL;
      ```

25. **CASE**
    - Evaluates a list of conditions and returns one of multiple possible result expressions.
    - Example:
      ```sql
      SELECT column1, 
             CASE
                 WHEN condition1 THEN result1
                 WHEN condition2 THEN result2
                 ELSE result3
             END AS result_column
      FROM table_name;
      ```

26. **EXISTS**
    - Tests for the existence of any rows in a subquery.
    - Example:
      ```sql
      SELECT column1 FROM table_name WHERE EXISTS (SELECT * FROM another_table WHERE condition);
      ```

27. **ANY/ALL**
    - Compares a value to a set of values returned by a subquery.
    - Example:
      ```sql
      SELECT column1 FROM table_name WHERE column1 > ALL (SELECT column2 FROM another_table);
      ```

28. **ORDER BY**
    - Sorts the result set in ascending or descending order.
    - Example:
      ```sql
      SELECT column1, column2 FROM table_name ORDER BY column1 ASC;
      ```

29. **GROUP BY**
    - Groups rows that have the same values into summary rows.
    - Example:
      ```sql
      SELECT COUNT(*), column1 FROM table_name GROUP BY column1;
      ```

30. **HAVING**
    - Filters groups based on specified conditions.
    - Example:
      ```sql
      SELECT column1, COUNT(*) FROM table_name GROUP BY column1 HAVING COUNT(*) > 1;
      ```

31. **PARTITION BY**
    - Divides the result set into partitions to which the window function is applied.
    - Example:
      ```sql
      SELECT column1, column2, AVG(column3) OVER (PARTITION BY column1) AS avg_column3 FROM table_name;
      ```

32. **WINDOW FUNCTION**
    - Performs a calculation across a set of table rows related to the current row.
    - Example:
      ```sql
      SELECT column1, column2, AVG(column3) OVER (PARTITION BY column1) AS avg_column3 FROM table_name;
      ```

33. **TRANSACTION**
    - Groups one or more SQL operations into a single unit of work that either succeeds completely or fails completely.
    - Example:
      ```sql
      START TRANSACTION;
      -- SQL statements --
      COMMIT;
      ```

34. **COMMIT**
    - Saves all changes made since the start of the current transaction.
    - Example:
      ```sql
      COMMIT;
      ```

35. **ROLLBACK**
    - Undoes all changes made in the current transaction.
    - Example:
      ```sql
      ROLLBACK;
      ```

36. **SAVEPOINT**
    - Sets a point in the transaction to which you can later roll back.
    - Example:
      ```sql
      SAVEPOINT savepoint_name;
      ```

37. **SET**
    - Sets session-level variables for the current session.
    - Example:
      ```sql
      SET @variable_name = value;
      ```

38. **GRANT**
    - Provides privileges to users.
    - Example:
      ```sql
      GRANT SELECT, INSERT ON table_name TO user_name;
      ```

39. **REVOKE**
    - Removes privileges from users.
    - Example:
      ```sql
      REVOKE SELECT ON table_name FROM user_name;
      ```

40. **CREATE TABLE**
    - Creates a new table in the database.
    - Example:
      ```sql
      CREATE TABLE table_name (
          column1 datatype,
          column2 datatype,
          ...
      );
      ```

41. **ALTER TABLE**
    - Modifies an existing table structure.
    - Example:
      ```sql
      ALTER TABLE table_name ADD column_name datatype;
      ```

42. **DROP TABLE**
    - Deletes an existing table from the database.
    - Example:
      ```sql
      DROP TABLE table_name;
      ```

43. **CREATE INDEX**
    - Creates an index on a table.
    - Example:
      ```sql
      CREATE INDEX idx_name ON table_name (column_name);
      ```

44. **DROP INDEX**
    - Deletes an existing index from the database.
    - Example:
      ```sql
      DROP INDEX idx_name ON table_name;
      ``

`

45. **CREATE VIEW**
    - Creates a virtual table based on the result set of a SELECT statement.
    - Example:
      ```sql
      CREATE VIEW view_name AS SELECT column1, column2 FROM table_name WHERE condition;
      ```

46. **DROP VIEW**
    - Deletes an existing view from the database.
    - Example:
      ```sql
      DROP VIEW view_name;
      ```

47. **CREATE PROCEDURE**
    - Creates a stored procedure in the database.
    - Example:
      ```sql
      CREATE PROCEDURE procedure_name
      AS
      BEGIN
          -- SQL statements --
      END;
      ```

48. **DROP PROCEDURE**
    - Deletes an existing stored procedure from the database.
    - Example:
      ```sql
      DROP PROCEDURE procedure_name;
      ```

49. **CREATE FUNCTION**
    - Creates a user-defined function in the database.
    - Example:
      ```sql
      CREATE FUNCTION function_name (parameters)
      RETURNS return_type
      BEGIN
          -- SQL statements --
      END;
      ```

50. **DROP FUNCTION**
    - Deletes an existing user-defined function from the database.
    - Example:
      ```sql
      DROP FUNCTION function_name;
      ```

This list covers the essential SQL clauses used for querying, managing, and manipulating data in relational databases.
Each clause has its specific use case and syntax, which may vary slightly depending on the SQL dialect (e.g., MySQL, PostgreSQL, Oracle SQL).
If you need further explanations or examples for any specific clause, feel free to ask!



