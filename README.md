# Oracle_Tools

>Oracle ASM

```
export ORACLE_SID=+ASM
export ORACLE_HOME=/u01/app/grid/product/19.0.0/grid
```

```
. oraenv
sqlplus / as sysasm
```

```
SHOW PARAMETER db_create_file_dest;
```
```
SELECT view_name
FROM v$fixed_view_definition
WHERE view_name LIKE 'V$ASM%'
ORDER BY view_name;	
```

```sh
srvctl start asm
```
> ## AWR - Report 

If you've generated the AWR report with the name `awr_new_test_report.html` but are unable to find where it was saved, follow these steps to locate the file:

### Check AWR report path and location - `find / -name "awr_new_test_report.html" 2>/dev/null`

### 1. **Default SQL*Plus Directory**
If you ran the `awrrpt.sql` script via **SQL*Plus** and didn't specify a directory, the report is saved in the directory from where SQL*Plus was launched. 

- Check the directory where you launched SQL*Plus. If you're on Linux or Unix, use the `pwd` command in the terminal before running SQL*Plus to check the current working directory.
  
### 2. **Find the Report in Known Oracle Directories**
You can check common Oracle directories like **`ORACLE_HOME`** or the **Data Pump directory**. Use the following query to check where the directory is located:

```sql
SELECT directory_path FROM dba_directories WHERE directory_name = 'DATA_PUMP_DIR';
```

This will show the path where Oracle typically saves output files. If you didn’t specify a directory, check in this directory for your AWR report file.

### 3. **Check File System for the Report**
Use the following commands based on your operating system to search for the file:

- **Linux/Unix:**
  Use the `find` command to search for the report by its name:

  ```bash
  find / -name "awr_new_test_report.html" 2>/dev/null
  ```

- **Windows:**
  Use Windows File Explorer’s search function or open a command prompt and run:

  ```cmd
  dir /s /p "awr_new_test_report.html"
  ```

This will search the entire directory tree for the report file.

### 4. **Re-run the Report with a Specific Path**
To avoid this issue in the future, you can specify a specific path when running the `awrrpt.sql` script.

```sql
SQL> @$ORACLE_HOME/rdbms/admin/awrrpt.sql
```

When prompted for the **report name** and **path**, you can explicitly provide a path like:

```plaintext
Enter the name of the report file: /home/oracle/reports/awr_new_test_report.html
```

This ensures the report is saved to the correct directory, making it easier to locate.

### 5. **Check for Errors**
Ensure that the report was successfully generated and that there were no errors during the execution of the `awrrpt.sql` script. If there were any issues, you may need to regenerate the report and specify the path explicitly.

<hr>

> ## Here's a consolidated list of the essential files and configurations needed for setting up and maintaining an Oracle standby database:

-- Control File Location

```sh
SET LINESIZE 150;
SET PAGESIZE 100;

SELECT 'Control File Location:' AS Description, name AS File_Location
FROM v$controlfile;

-- Data File Locations
SELECT 'Data Files Location:' AS Description, tablespace_name, file_name
FROM dba_data_files;

-- Redo Log File Locations
SELECT 'Redo Log Files Location:' AS Description, group# AS Log_Group, member AS Log_File
FROM v$logfile;

-- Archived Log File Locations
SELECT 'Archived Log Files Location:' AS Description, thread#, sequence#, name AS Archived_Log_File
FROM v$archived_log;

-- Parameter File Location
SELECT 'Parameter File Location:' AS Description, value AS Parameter_File_Location
FROM v$parameter
WHERE name = 'spfile';
```
<hr>

```sh
SET LINESIZE 150;
SET PAGESIZE 100;

-- Control File Location
SELECT 'Control File' AS File_Type, name AS File_Location
FROM v$controlfile
UNION ALL

-- Data File Locations
SELECT 'Data File' AS File_Type, file_name AS File_Location
FROM dba_data_files
UNION ALL

-- Redo Log File Locations
SELECT 'Redo Log File' AS File_Type, member AS File_Location
FROM v$logfile
UNION ALL

-- Archived Log File Locations
SELECT 'Archived Log File' AS File_Type, name AS File_Location
FROM v$archived_log
WHERE name IS NOT NULL
UNION ALL

-- Parameter File (SPFILE) Location
SELECT 'SPFILE' AS File_Type, value AS File_Location
FROM v$parameter
WHERE name = 'spfile';

-- If using a PFILE instead of an SPFILE:
SELECT 'PFILE' AS File_Type, value AS File_Location
FROM v$parameter
WHERE name = 'pfile';
```
<hr>

> If you have accidentally deleted the control files of your Oracle database, you cannot start the database directly because the control files are critical for the database's operation. You will need to recover or recreate the control files to bring the database back online.

Here’s what you can do to recover from this situation:

### Steps to Recover Deleted Control Files

1. **Shutdown the Database (if it is still running)**
   - First, ensure that the database is shut down properly. If the instance is still running, you should immediately shut it down gracefully.
   
   ```sql
   shutdown immediate;
   ```

2. **Check for Control File Backups**
   - If you have a backup of your control files, you can restore them. Oracle RMAN (Recovery Manager) or OS-level backups may have the control files.

3. **Restore Control Files from Backup (using RMAN)**

   If you have an RMAN backup of the control file, follow these steps:

   - Start RMAN:
     ```bash
     rman target /
     ```

   - Restore the control file from the backup:
     ```bash
     restore controlfile from autobackup;
     ```

   - Mount the database:
     ```bash
     alter database mount;
     ```

   - Recover the database:
     ```bash
     recover database;
     ```

   - Open the database:
     ```bash
     alter database open;
     ```

4. **Recreate the Control Files (if no backup is available)**

   If you don’t have a backup of the control files, you can recreate the control files manually. Follow these steps:

   - First, create a new control file. You will need a backup of your database or have access to the metadata to recreate the control file. Use the following steps as an example:

     a) Start the database in **nomount** mode:
     
     ```sql
     startup nomount;
     ```

     b) Use a previously saved **control file creation script** (or you need to generate one if you don’t have it).

     Example control file creation script:
     ```sql
     CREATE CONTROLFILE REUSE DATABASE "ORADB" RESETLOGS ARCHIVELOG
     MAXLOGFILES 16
     MAXLOGMEMBERS 3
     MAXDATAFILES 100
     MAXINSTANCES 8
     MAXLOGHISTORY 292
     LOGFILE
       GROUP 1 '/u01/app/oracle/oradata/ORADB/redo01.log' SIZE 50M,
       GROUP 2 '/u01/app/oracle/oradata/ORADB/redo02.log' SIZE 50M,
       GROUP 3 '/u01/app/oracle/oradata/ORADB/redo03.log' SIZE 50M
     DATAFILE
       '/u01/app/oracle/oradata/ORADB/system01.dbf',
       '/u01/app/oracle/oradata/ORADB/sysaux01.dbf',
       '/u01/app/oracle/oradata/ORADB/undotbs01.dbf',
       '/u01/app/oracle/oradata/ORADB/users01.dbf'
     CHARACTER SET AL32UTF8;
     ```

     c) Run the control file creation script in SQL*Plus:
     
     ```sql
     CREATE CONTROLFILE REUSE DATABASE "ORADB" RESETLOGS ARCHIVELOG
     LOGFILE
       GROUP 1 '/u01/app/oracle/oradata/ORADB/redo01.log' SIZE 50M,
       GROUP 2 '/u01/app/oracle/oradata/ORADB/redo02.log' SIZE 50M;
     ```

5. **Perform Database Recovery**

   - After recreating the control file, you will need to recover the database:
   
   ```sql
   recover database using backup controlfile;
   ```

6. **Open the Database with RESETLOGS**
   - Once the recovery is complete, open the database with `RESETLOGS` to synchronize the logs:

   ```sql
   alter database open resetlogs;
   ```

### Important Notes:
- **Backup Regularly**: Always keep multiple backups of your control files. RMAN's `autobackup` feature is especially helpful in this case.
- **RESETLOGS**: Opening the database with `RESETLOGS` will reset the log sequence numbers. Be cautious and ensure you are prepared for this action.

If you restore the control files or recreate them, the database should be able to start up normally once recovery is complete.

<hr>

> ## Important Location in database

1. spfile location </br>
/u01/app/oracle/product/19.0.0/db_1/dbs/
       
2. ctl first file location location	</br>
/u01/app/oracle/oradata/ORADB/control01.ctl

2. FRA ctl Second file location location </br>
/u01/app/oracle/fra/ORADB/

4. trace alart log file location </br>
/u01/app/oracle/diag/rdbms/oradb/oradb/trace/

5. Awr and all report sql script location </br>
/u01/app/oracle/product/19.0.0/db_1/rdbms/admin/
