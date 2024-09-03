-- At the Primary - Add 1 record
INSERT INTO employee (emp_id,emp_name) VALUES (1,'Rock');
COMMIT;
COLUMN DATE_OF_JOINING   FORMAT A30;
SELECT * FROM employee;

-- At the Primary 
exec dbms_service.create_service('ORA_PRIMARY','ORA_PRIMARY');
exec dbms_service.start_service ('ORA_PRIMARY');

CREATE TRIGGER start_primary 
    AFTER STARTUP ON DATABASE 
    
	DECLARE database_role VARCHAR2(16);
BEGIN
    SELECT
        database_role
    INTO database_role
    FROM
        v$database;

    IF database_role = 'PRIMARY' THEN
        dbms_service.start_service('ORA_PRIMARY');
    END IF;
END;
/

SELECT name FROM v$active_services;

-- At the Client/Application SERVER
ORA =
  (DESCRIPTION =
   (ADDRESS_LIST =
    (LOAD_BALANCE = OFF)
    (FAILOVER = ON)
    (ADDRESS = (PROTOCOL = TCP)(HOST = WIN19PRIMARY)(PORT = 1522))
    (ADDRESS = (PROTOCOL = TCP)(HOST = WIN19STANDBY)(PORT = 1522))
   )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORA_PRIMARY)
    )
  )

-- From App Server/Client
sqlplus sys/password@ORA as sysdba
  
ALTER SESSION SET nls_date_format='DD-MON-YYYY HH24:MI:SS';

COLUMN DB_UNIQUE_NAME    FORMAT A10;
COLUMN DATABASE_ROLE     FORMAT A20;
COLUMN SWITCHOVER_STATUS FORMAT A20;
COLUMN HOST_NAME         FORMAT A15;
COLUMN MACHINE           FORMAT A15;
SELECT host_name, db_unique_name, database_role, switchover_status FROM v$database, v$instance;
SELECT machine, logon_time FROM v$session WHERE machine = 'WIN16';

-- Convert Primary Database to Standby
CONNECT / AS SYSDBA

COLUMN DB_UNIQUE_NAME    FORMAT A10;
COLUMN DATABASE_ROLE     FORMAT A20;
COLUMN SWITCHOVER_STATUS FORMAT A20;
COLUMN HOST_NAME         FORMAT A15; 
COLUMN MACHINE           FORMAT A15;
SELECT host_name, db_unique_name, database_role, switchover_status FROM v$database, v$instance;

SELECT DB_UNIQUE_NAME, DATABASE_ROLE, SWITCHOVER_STATUS FROM V$DATABASE;
ALTER  DATABASE COMMIT TO SWITCHOVER TO STANDBY WITH SESSION SHUTDOWN;
STARTUP;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
SELECT host_name, db_unique_name, database_role, switchover_status FROM v$database, v$instance;

-- Convert Standby Database to Primary
CONNECT / AS SYSDBA
COLUMN DB_UNIQUE_NAME    FORMAT A10;
COLUMN DATABASE_ROLE     FORMAT A20;
COLUMN SWITCHOVER_STATUS FORMAT A20;
COLUMN HOST_NAME         FORMAT A15; 
COLUMN MACHINE           FORMAT A15;
SELECT host_name, db_unique_name, database_role, switchover_status FROM v$database, v$instance;
	
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE FINISH;
ALTER  DATABASE COMMIT TO SWITCHOVER TO PRIMARY WITH SESSION SHUTDOWN;
SHUTDOWN IMMEDIATE;
STARTUP;
SELECT host_name, db_unique_name, database_role, switchover_status FROM v$database, v$instance;

-- From App Server/Client -- After Failover
sqlplus sys/password@ORA as sysdba

COLUMN DB_UNIQUE_NAME    FORMAT A10;
COLUMN DATABASE_ROLE     FORMAT A20;
COLUMN SWITCHOVER_STATUS FORMAT A20;
COLUMN HOST_NAME         FORMAT A15; 
COLUMN MACHINE           FORMAT A15;
SELECT host_name, db_unique_name, database_role, switchover_status FROM v$database, v$instance;
	
COLUMN DATE_OF_JOINING   FORMAT A30;
SELECT * FROM employee;


-- CLEAN UP
exec dbms_service.stop_service  ('ORA_PRIMARY');
exec dbms_service.delete_service('ORA_PRIMARY');

drop trigger start_primary;
commit;



