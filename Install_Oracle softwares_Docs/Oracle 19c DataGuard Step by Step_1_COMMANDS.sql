#--------- For Youtube - Same script -- Line added to avoid duplicates

#--- Run Below commands on BOTH Nodes

mkdir -p /dbi/oracle/V19BaseDatabase/admin/ora/adump
mkdir /dbd/oradata/ora
mkdir /dbd/oradata/ora/fra/
mkdir /dbd/oradata/ora/arch1

lsnrctl start  lsnrv19
cd /home/oracle/DATAGUARD/
cat dbca_ora.rsp
dbca -silent -createDatabase -responseFile dbca_ora.rsp

#--------- Setup  Primary orap setup_01_primary.sql on NODE1 - db1 - Primary

. oraenv
ora
sqlplus / as sysdba

SELECT NAME, DB_UNIQUE_NAME, OPEN_MODE, LOG_MODE, FLASHBACK_ON, FORCE_LOGGING FROM V$DATABASE;

SHOW PARAMETER NAME;
ALTER SYSTEM SET DB_UNIQUE_NAME='orap'   SCOPE=SPFILE; 
ALTER SYSTEM RESET DB_RECOVERY_FILE_DEST SCOPE=SPFILE;

ALTER SYSTEM SET LOG_ARCHIVE_DEST_1=
'LOCATION=/dbd/oradata/ora/arch1/
VALID_FOR=(ALL_LOGFILES,ALL_ROLES)
DB_UNIQUE_NAME=orap' scope=spfile;

SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
SHOW PARAMETER NAME;

ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
ARCHIVE LOG LIST;
ALTER DATABASE FORCE LOGGING;
ALTER SYSTEM SET LOCAL_LISTENER='db1:1522';
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=30;
ALTER SYSTEM SET LOG_ARCHIVE_FORMAT='ora_%t_%s_%r.arc' SCOPE=SPFILE; 
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST_SIZE = 10G      SCOPE=BOTH;
ALTER SYSTEM SET DB_RECOVERY_FILE_DEST = '/dbd/oradata/ora/fra/'  SCOPE=BOTH;
ALTER SYSTEM SET DB_FLASHBACK_RETENTION_TARGET = 60    SCOPE=BOTH;
ALTER DATABASE FLASHBACK ON;
ALTER SYSTEM SET REMOTE_LOGIN_PASSWORDFILE=EXCLUSIVE   SCOPE=SPFILE;
SHUTDOWN IMMEDIATE;
STARTUP;
CREATE PFILE FROM SPFILE;

#--------- Setup Standby oras

. oraenv
ora
sqlplus / as sysdba

cd $ORACLE_HOME/dbs

scp initora.ora db2:$ORACLE_HOME/dbs
scp orapwora    db2:$ORACLE_HOME/dbs

gedit $ORACLE_HOME/dbs/initora.ora 
   1. Replace orap with oras for db_unique_name
   2. Change the LOCAL_LISTENER to db2:1522

gedit /etc/oratab - add ora:/dbi/oracle/V19Database:N

Then edit tnsnames.ora and listener.ora (Bottom of this text file)

cat $ORACLE_HOME/network/admin/listener.ora
cat $ORACLE_HOME/network/admin/tnsnames.ora

--Then restart listener

lsnrctl stop   lsnrv19 
lsnrctl start  lsnrv19


#--------- Setup Standby oras - Restore

mkdir -p /dbi/oracle/V19BaseDatabase/admin/ora/adump
mkdir /dbd/oradata/ora
mkdir /dbd/oradata/ora/fra/
mkdir /dbd/oradata/ora/arch1

. oraenv
ora

SHUT ABORT;
STARTUP NOMOUNT pfile="$ORACLE_HOME/dbs/initora.ora";
SHOW PARAMETER NAME;

-- RUN Duplicate command from PRIMARY - db1

rman TARGET sys/password@orap AUXILIARY sys/password@oras

DUPLICATE TARGET DATABASE
  FOR STANDBY
  FROM ACTIVE DATABASE
  DORECOVER
  SPFILE
    SET db_unique_name='oras' COMMENT 'IS STANDBY'
  NOFILENAMECHECK;
 
#--------- Setup Primary orap - setup_02_primary_dg.sql

. oraenv
ora

ARCHIVE LOG LIST;
SHOW PARAMETER NAME;
SELECT MEMBER FROM V$LOGFILE;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 4 ('/dbd/oradata/ora/redo04.log') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 5 ('/dbd/oradata/ora/redo05.log') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 6 ('/dbd/oradata/ora/redo06.log') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 7 ('/dbd/oradata/ora/redo07.log') SIZE 200M; 
select thread#, group#, sequence#, status, bytes from v$standby_log;

SELECT MEMBER FROM V$LOGFILE ORDER BY GROUP#;

ALTER SYSTEM SET LOG_ARCHIVE_DEST_1=
'LOCATION=/dbd/oradata/ora/arch1/
VALID_FOR=(ALL_LOGFILES,ALL_ROLES)
DB_UNIQUE_NAME=orap' SCOPE=spfile;

ALTER SYSTEM SET LOG_ARCHIVE_DEST_2=
'SERVICE=oras LGWR ASYNC
VALID_FOR=(ALL_LOGFILES,PRIMARY_ROLE)
DB_UNIQUE_NAME=oras' SCOPE=SPFILE;

ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(orap,oras)';
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM ARCHIVE LOG CURRENT;

ALTER SYSTEM SET FAL_CLIENT='orap';
ALTER SYSTEM SET FAL_SERVER='oras';
ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO;

ALTER DATABASE SET STANDBY DATABASE TO MAXIMIZE PERFORMANCE;

SHUTDOWN IMMEDIATE;
STARTUP;
CREATE PFILE FROM SPFILE;
ALTER SESSION SET nls_date_format='DD-MON-YYYY HH24:MI:SS';
SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED   FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;
SELECT DB_UNIQUE_NAME, SWITCHOVER_STATUS, DATABASE_ROLE, OPEN_MODE FROM V$DATABASE;

#--------- Setup Standby setup_03_standby_dg.sql

ALTER DATABASE CREATE STANDBY CONTROLFILE AS '/dbd/oradata/ora/control_standby.ctl';
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;

SHOW PARAMETER NAME;
SELECT MEMBER FROM V$LOGFILE;
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 4 ('/dbd/oradata/ora/redo04.log') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 5 ('/dbd/oradata/ora/redo05.log') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 6 ('/dbd/oradata/ora/redo06.log') SIZE 200M; 
ALTER DATABASE ADD STANDBY LOGFILE THREAD 1 GROUP 7 ('/dbd/oradata/ora/redo07.log') SIZE 200M; 
select thread#, group#, sequence#, status, bytes from v$standby_log;
SELECT MEMBER FROM V$LOGFILE ORDER BY GROUP#;

ALTER SYSTEM SET LOG_ARCHIVE_DEST_1=
'LOCATION=/dbd/oradata/ora/arch1/
VALID_FOR=(ALL_LOGFILES,ALL_ROLES)
DB_UNIQUE_NAME=oras' SCOPE=spfile;

ALTER SYSTEM SET LOG_ARCHIVE_DEST_2=
'SERVICE=orap LGWR ASYNC
VALID_FOR=(ALL_LOGFILES,PRIMARY_ROLE)
DB_UNIQUE_NAME=orap' SCOPE=SPFILE;

ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE;
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=30;
ALTER SYSTEM SET LOG_ARCHIVE_FORMAT='ora_%t_%s_%r.arc' SCOPE=SPFILE;
ALTER SYSTEM SET REMOTE_LOGIN_PASSWORDFILE=EXCLUSIVE SCOPE=SPFILE;

ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(oras,orap)';
ALTER SYSTEM SET FAL_CLIENT='oras';
ALTER SYSTEM SET FAL_SERVER='orap';
ALTER SYSTEM SET LOCAL_LISTENER='db2:1522';

ALTER SYSTEM SET STANDBY_FILE_MANAGEMENT=AUTO;
ALTER DATABASE SET STANDBY DATABASE TO MAXIMIZE PERFORMANCE;
ALTER DATABASE FLASHBACK ON;
SHUTDOWN IMMEDIATE;
STARTUP;
CREATE PFILE FROM SPFILE;

ALTER DATABASE RECOVER MANAGED STANDBY DATABASE USING CURRENT LOGFILE DISCONNECT FROM SESSION;

ALTER SESSION SET nls_date_format='DD-MON-YYYY HH24:MI:SS';
SELECT SEQUENCE#, FIRST_TIME, NEXT_TIME, APPLIED   FROM V$ARCHIVED_LOG ORDER BY SEQUENCE#;
SELECT DB_UNIQUE_NAME, SWITCHOVER_STATUS, DATABASE_ROLE, OPEN_MODE FROM V$DATABASE;

#--------- Testing

CREATE TABLE TEST1 (C1 INT PRIMARY KEY, C2 CHAR(6));

INSERT INTO TEST1 VALUES (52, 'rap');
INSERT INTO TEST1 VALUES (56, 'cap');
COMMIT;
ALTER SYSTEM CHECKPOINT;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM archIVE LOG CURRENT;
SELECT * FROM TEST1;

DELETE FROM TEST1;

INSERT INTO TEST1 VALUES (53, 'trap');
INSERT INTO TEST1 VALUES (54, 'vamp');
INSERT INTO TEST1 VALUES (61, 'help');
INSERT INTO TEST1 VALUES (66, 'trapped');
COMMIT;
ALTER SYSTEM CHECKPOINT;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM ARCHIVE LOG CURRENT;
SELECT * FROM TEST1;

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
DGMGRL> edit database orap set property staticconnectidentifier='(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(PORT=1522)(HOST=db1))(CONNECT_DATA=(SERVICE_NAME=ora)(INSTANCE_NAME=ora)(SERVER=DEDICATED)))';
DGMGRL> edit database oras set property staticconnectidentifier='(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(PORT=1522)(HOST=db2))(CONNECT_DATA=(SERVICE_NAME=ora)(INSTANCE_NAME=ora)(SERVER=DEDICATED)))';
DGMGRL> edit database orap set property ApplyLagThreshold=0;
DGMGRL> edit database orap set property TransportLagThreshold=0;
DGMGRL> edit database oras set property ApplyLagThreshold=0;
DGMGRL> edit database oras set property TransportLagThreshold=0;
DGMGRL> enable configuration;
DGMGRL> show configuration;
DGMGRL> switchover to 'oras';

--- below to set FAST_START FAILOVER

-- Verify the Data Guard Status in sqlplus
SELECT DB_UNIQUE_NAME, DATABASE_ROLE, SWITCHOVER_STATUS  FROM V$DATABASE;

--- Connect DGMGRL Session

dgmgrl sys/password as sysdba

DGMGRL> show configuration;
DGMGRL> edit database orap set property 'LogXptMode'='sync';
DGMGRL> edit database oras set property 'LogXptMode'='sync';
DGMGRL> edit configuration set protection mode as maxavailability;
DGMGRL> enable  configuration;
DGMGRL> enable fast_start failover;
DGMGRL> show configuration;
DGMGRL> show fast_start failover;

-- Start Observer

nohup dgmgrl sys/password@orap "start observer file='$ORACLE_HOME/dbs/fsfo.dat'" -logfile $HOME/observer.log &


#--------- Reference Files
[oracle@db1 ~]$ cat $ORACLE_HOME/network/admin/listener.ora
LSNRV19 =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = db1.db.com)(PORT = 1522))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1522))
    )
  )

SID_LIST_LSNRV19 =
  (SID_LIST =
    (SID_DESC = (GLOBAL_DBNAME = ora) (ORACLE_HOME = /dbi/oracle/V19Database) (SID_NAME = ora))
  )

[oracle@db1 ~]$ cat $ORACLE_HOME/network/admin/tnsnames.ora
orap =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = db1.db.com)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ora)))

oras =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = db2.db.com)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ora)))


[oracle@db2 ~]$ cat $ORACLE_HOME/network/admin/listener.ora
LSNRV19 =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = db2.db.com)(PORT = 1522))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1522))
    )
  )

SID_LIST_LSNRV19 =
  (SID_LIST =
    (SID_DESC = (GLOBAL_DBNAME = ora) (ORACLE_HOME = /dbi/oracle/V19Database) (S                                                       ID_NAME = ora))
  )
[oracle@db2 ~]$ cat $ORACLE_HOME/network/admin/tnsnames.ora
orap =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = db1.db.com)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ora)))

oras =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = db2.db.com)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ora)))
[oracle@db2 ~]$