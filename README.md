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

