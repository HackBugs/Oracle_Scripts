#--------- Configure DataGuard Broker

SELECT DB_UNIQUE_NAME, DATABASE_ROLE, SWITCHOVER_STATUS, OPEN_MODE FROM V$DATABASE;

-- Set below on PRIMARY AND STANDBY
alter system set DG_BROKER_START=TRUE SCOPE=BOTH;

-- Run below command on oras - db2 - First Standby
alter system set LOG_ARCHIVE_DEST_2='';
 
--- Connect DGMGRL Session on Primary
dgmgrl sys/password as sysdba

DGMGRL> show configuration;
DGMGRL> create configuration 'ora' as primary database is 'orap' connect identifier is orap;
DGMGRL> add database 'oras' as connect identifier is 'oras' maintained as physical;
DGMGRL> show configuration;
DGMGRL> edit database orap set property staticconnectidentifier='(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(PORT=1522)(HOST=WIN19PRIMARY))(CONNECT_DATA=(SERVICE_NAME=ora)(INSTANCE_NAME=ora)(SERVER=DEDICATED)))';
DGMGRL> edit database oras set property staticconnectidentifier='(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(PORT=1522)(HOST=WIN19STANDBY))(CONNECT_DATA=(SERVICE_NAME=ora)(INSTANCE_NAME=ora)(SERVER=DEDICATED)))';
DGMGRL> edit database orap set property ApplyLagThreshold=0;
DGMGRL> edit database orap set property TransportLagThreshold=0;
DGMGRL> edit database oras set property ApplyLagThreshold=0;
DGMGRL> edit database oras set property TransportLagThreshold=0;
DGMGRL> enable configuration;
DGMGRL> show configuration;
DGMGRL> switchover to 'oras';

-- Verify the Data Guard Status in sqlplus
SELECT DB_UNIQUE_NAME, DATABASE_ROLE, SWITCHOVER_STATUS  FROM V$DATABASE;

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

COLUMN DATE_OF_JOINING   FORMAT A30;
SELECT * FROM employee;

INSERT INTO employee (emp_id,emp_name) VALUES (3,'Air');
COMMIT;
ALTER SYSTEM CHECKPOINT;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM ARCHIVE LOG CURRENT;

COLUMN DATE_OF_JOINING   FORMAT A30;
SELECT * FROM employee;

INSERT INTO employee (emp_id,emp_name) VALUES (4,'Stone');
COMMIT;
ALTER SYSTEM CHECKPOINT;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM ARCHIVE LOG CURRENT;

COLUMN DATE_OF_JOINING   FORMAT A30;
SELECT * FROM employee;

COLUMN DB_UNIQUE_NAME    FORMAT A10;
COLUMN DATABASE_ROLE     FORMAT A20;
COLUMN SWITCHOVER_STATUS FORMAT A20;
COLUMN HOST_NAME         FORMAT A15;
COLUMN MACHINE           FORMAT A15;
host cls
SELECT host_name, db_unique_name, database_role, switchover_status FROM v$database, v$instance;

-- Reference ONLY
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE DISCONNECT FROM SESSION;
