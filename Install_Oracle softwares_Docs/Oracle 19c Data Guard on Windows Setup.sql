#--- Set Environmental Variables

ORACLE_HOME=C:\Oracle\V19Database
ORACLE_BASE=C:\Oracle\V19DatabaseBase
ORACLE_SID=ORA

[Environment]::SetEnvironmentVariable("ORACLE_BASE", "C:\Oracle\V19DatabaseBase", "Machine")
[Environment]::SetEnvironmentVariable("ORACLE_HOME", "C:\Oracle\V19Database", "Machine")
[Environment]::SetEnvironmentVariable("ORACLE_SID", "ORA", "Machine")

#--- Create LISTENER with port 1522 on both Machines

netca

#--- Run Below commands on BOTH Nodes (Create directories/folders for Oracle Database)

mkdir D:\ORADATA\
mkdir D:\ORADATA\ORA\
mkdir D:\ORADATA\ORA\FRA

#--------- Setup  Primary ORAP setup_01_primary.sql on NODE1 - WIN19PRIMARY - Primary

. oraenv
ora
sqlplus / as sysdba

STARTUP MOUNT;

SELECT NAME, DB_UNIQUE_NAME, OPEN_MODE, LOG_MODE, FLASHBACK_ON, FORCE_LOGGING FROM V$DATABASE;

SHOW PARAMETER NAME;
ALTER SYSTEM SET DB_UNIQUE_NAME='ORAP'                       SCOPE=SPFILE; 
ALTER SYSTEM SET REMOTE_LOGIN_PASSWORDFILE=EXCLUSIVE         SCOPE=SPFILE;
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST_SIZE = 10G            SCOPE=BOTH;
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST='D:\ORADATA\ORA\FRA'  SCOPE=BOTH;

SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
SHOW PARAMETER NAME;

ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
ARCHIVE LOG LIST;

ALTER SYSTEM SET DB_FLASHBACK_RETENTION_TARGET = 60    SCOPE=BOTH;
ALTER DATABASE FLASHBACK ON;
ALTER DATABASE FORCE LOGGING;

ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=USE_DB_RECOVERY_FILE_DEST VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=ORAP' SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=ORAS LGWR ASYNC VALID_FOR=(ALL_LOGFILES,PRIMARY_ROLE)         DB_UNIQUE_NAME=ORAS' SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE            SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE            SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(ORAS,ORAP)' SCOPE=BOTH;
ALTER SYSTEM SET FAL_CLIENT='ORAP'                          SCOPE=BOTH;
ALTER SYSTEM SET FAL_SERVER='ORAS'                          SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=30               SCOPE=BOTH;
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO               SCOPE=BOTH;
ALTER SYSTEM SET LOCAL_LISTENER='WIN19PRIMARY:1522'         SCOPE=BOTH;
ALTER SYSTEM REGISTER;

ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 4 ('D:\ORADATA\ORA\REDO04.LOG') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 5 ('D:\ORADATA\ORA\REDO05.LOG') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 6 ('D:\ORADATA\ORA\REDO06.LOG') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 7 ('D:\ORADATA\ORA\REDO07.LOG') SIZE 200M; 

SELECT thread#, group#, sequence#, status, bytes FROM v$standby_log;

SELECT MEMBER FROM V$LOGFILE ORDER BY GROUP#;

ALTER SYSTEM SWITCH LOGFILE;

ALTER DATABASE SET STANDBY DATABASE TO MAXIMIZE PERFORMANCE;

CREATE PFILE FROM SPFILE;

#--------- Setup Standby ORAS on NODE2 - WIN19STANDBY - Standby

. oraenv
ora
sqlplus / as sysdba

cd $ORACLE_HOME/dbs

Copy INITORA.ORA  to WIN19STANDBY:%ORACLE_HOME%/database
Copy PWDORA.ora   to WIN19STANDBY:%ORACLE_HOME%/database

gedit $ORACLE_HOME/dbs/initora.ora 
   1. Replace ORAP with ORAS for db_unique_name
   2. Change the LOCAL_LISTENER to WIN19STANDBY:1522

Then edit tnsnames.ora and listener.ora (Bottom of this text file)

#--------- Setup Standby ORAS - Restore

mkdir D:\ORADATA\
mkdir D:\ORADATA\ORA\
mkdir D:\ORADATA\ORA\FRA

oradim -NEW -SID ORA -STARTMODE manual -PFILE "C:\Oracle\V19Database\database\INITORA.ORA"

. oraenv
ora

SHUT ABORT;
STARTUP NOMOUNT;
SHOW PARAMETER NAME;

-- RUN Duplicate command from NODE2 - WIN19STANDBY - Standby

rman TARGET sys/password@ORAP AUXILIARY sys/password@ORAS

DUPLICATE TARGET DATABASE
  FOR STANDBY
  FROM ACTIVE DATABASE
  DORECOVER
  SPFILE
    SET db_unique_name='ORAS' COMMENT 'IS STANDBY'
  NOFILENAMECHECK;
 
#--------- Setup Standby setup_02_standby_dg.sql

SHOW PARAMETER NAME;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_1='LOCATION=USE_DB_RECOVERY_FILE_DEST VALID_FOR=(ALL_LOGFILES,ALL_ROLES) DB_UNIQUE_NAME=ORAS' SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_2='SERVICE=ORAP LGWR ASYNC VALID_FOR=(ALL_LOGFILES,PRIMARY_ROLE)         DB_UNIQUE_NAME=ORAP' SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE            SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE            SCOPE=BOTH;
ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(ORAS,ORAP)' SCOPE=BOTH;
ALTER SYSTEM SET FAL_CLIENT='ORAS'                          SCOPE=BOTH;
ALTER SYSTEM SET FAL_SERVER='ORAP'                          SCOPE=BOTH;
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO               SCOPE=BOTH;
ALTER SYSTEM SET LOCAL_LISTENER='WIN19STANDBY:1522'         SCOPE=BOTH;
ALTER SYSTEM REGISTER;

ALTER DATABASE SET STANDBY DATABASE TO MAXIMIZE PERFORMANCE;
ALTER DATABASE FLASHBACK ON;
ALTER DATABASE OPEN;
CREATE PFILE FROM SPFILE;

ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;

ALTER SESSION SET nls_date_format='DD-MON-YYYY HH24:MI:SS';
SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED   FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;
SELECT DB_UNIQUE_NAME, SWITCHOVER_STATUS, DATABASE_ROLE, OPEN_MODE FROM V$DATABASE;

#--------- Setup Primary ORAP - setup_03_primary_dg.sql

ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM ARCHIVE LOG CURRENT;

ALTER SESSION SET nls_date_format='DD-MON-YYYY HH24:MI:SS';
SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;
SELECT DB_UNIQUE_NAME, DATABASE_ROLE, SWITCHOVER_STATUS, OPEN_MODE   FROM V$DATABASE;

#--------- Testing
DROP TABLE employee;
COMMIT;
CREATE TABLE employee (
    emp_id          INT,
    emp_name        VARCHAR2(12),
    date_of_joining TIMESTAMP DEFAULT systimestamp
);

INSERT INTO employee (emp_id,emp_name) VALUES (1,'Rock');
INSERT INTO employee (emp_id,emp_name) VALUES (2,'Water');

COMMIT;
ALTER SYSTEM CHECKPOINT;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM ARCHIVE LOG CURRENT;
SELECT * FROM employee;

INSERT INTO employee (emp_id,emp_name) VALUES (3,'Air');
COMMIT;
ALTER SYSTEM CHECKPOINT;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM ARCHIVE LOG CURRENT;
SELECT * FROM employee;

INSERT INTO employee (emp_id,emp_name) VALUES (4,'Stone');
COMMIT;
ALTER SYSTEM CHECKPOINT;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM ARCHIVE LOG CURRENT;
SELECT * FROM employee;

-- Convert primary database to standby
CONNECT / AS SYSDBA
SELECT DATABASE_ROLE, SWITCHOVER_STATUS, OPEN_MODE FROM V$DATABASE;
ALTER  DATABASE COMMIT TO SWITCHOVER TO STANDBY WITH SESSION SHUTDOWN;
STARTUP;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
SELECT DATABASE_ROLE, SWITCHOVER_STATUS, OPEN_MODE FROM V$DATABASE;

-- Convert standby database to primary
CONNECT / AS SYSDBA
SELECT DATABASE_ROLE, SWITCHOVER_STATUS, OPEN_MODE FROM V$DATABASE;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE FINISH;
ALTER  DATABASE COMMIT TO SWITCHOVER TO PRIMARY WITH SESSION SHUTDOWN;
SHUTDOWN IMMEDIATE;
STARTUP;
SELECT DATABASE_ROLE, SWITCHOVER_STATUS, OPEN_MODE FROM V$DATABASE;


--#WIN19PRIMARY
C:\Oracle\V19Database\network\admin>type listener.ora

SID_LIST_LISTENER =
  (SID_LIST =
   (SID_DESC =
      (ORACLE_HOME = C:\Oracle\V19Database)
      (SID_NAME = ORA)
    )
  )
  
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = WIN19PRIMARY)(PORT = 1522))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1522))
    )
  )

C:\Oracle\V19Database\network\admin>type tnsnames.ora

ORAP =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = WIN19PRIMARY)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ORAP)))

ORAS =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = WIN19STANDBY)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ORAS)))


--#WIN19STANDBY

C:\Oracle\V19Database\network\admin>type listener.ora

SID_LIST_LISTENER =
  (SID_LIST =
   (SID_DESC =
      (ORACLE_HOME = C:\Oracle\V19Database)
      (SID_NAME = ORA)
    )
  )

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = WIN19STANDBY)(PORT = 1522))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1522))
    )
  )

C:\Oracle\V19Database\network\admin>type tnsnames.ora

ORAP =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = WIN19PRIMARY)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ORAP)))

ORAS =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = WIN19STANDBY)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ORAS)))















--#ORAP
SQL> show parameter name;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
cdb_cluster_name                     string
cell_offloadgroup_name               string
db_file_name_convert                 string
db_name                              string      ORA
db_unique_name                       string      ORAP
global_names                         boolean     FALSE
instance_name                        string      ora
lock_name_space                      string
log_file_name_convert                string
pdb_file_name_convert                string
processor_group_name                 string

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
service_names                        string      ORAP
SQL> show parameter local_list;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
local_listener                       string      WIN19PRIMARY:1522


--#ORAS
SQL> show parameter name;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
cdb_cluster_name                     string
cell_offloadgroup_name               string
db_file_name_convert                 string
db_name                              string      ORA
db_unique_name                       string      ORAS
global_names                         boolean     FALSE
instance_name                        string      ora
lock_name_space                      string
log_file_name_convert                string
pdb_file_name_convert                string
processor_group_name                 string

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
service_names                        string      ORAS
SQL> show parameter local_list;

NAME                                 TYPE        VALUE
------------------------------------ ----------- ------------------------------
local_listener                       string      WIN19STANDBY:1522
