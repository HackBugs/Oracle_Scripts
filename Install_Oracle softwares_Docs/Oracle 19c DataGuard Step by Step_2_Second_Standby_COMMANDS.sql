#--------- Setup 2nd Standby orat - Restore

. oraenv
ora
sqlplus / as sysdba

cd $ORACLE_HOME/dbs

scp initora.ora db3:$ORACLE_HOME/dbs
scp orapwora    db3:$ORACLE_HOME/dbs

gedit $ORACLE_HOME/dbs/initora.ora 
   1. Replace orap with orat for db_unique_name
   2. Change the LOCAL_LISTENER to db3:1522

gedit /etc/oratab - add ora:/dbi/oracle/V19Database:N

Then edit tnsnames.ora and listener.ora (Bottom of this text file)

cat $ORACLE_HOME/network/admin/listener.ora
cat $ORACLE_HOME/network/admin/tnsnames.ora

--Then restart listener

lsnrctl stop   lsnrv19 
lsnrctl start  lsnrv19

----------------------

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

rman TARGET sys/password@orap AUXILIARY sys/password@orat

DUPLICATE TARGET DATABASE
  FOR STANDBY
  FROM ACTIVE DATABASE
  DORECOVER
  SPFILE
    SET db_unique_name='orat' COMMENT 'IS STANDBY'
  NOFILENAMECHECK;
 
#--------- Setup Standby setup_06_2nd_standby_dg.sql

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
DB_UNIQUE_NAME=orat' SCOPE=spfile;

ALTER SYSTEM SET LOG_ARCHIVE_DEST_2=
'SERVICE=orap LGWR ASYNC
VALID_FOR=(ALL_LOGFILES,PRIMARY_ROLE)
DB_UNIQUE_NAME=orap' SCOPE=SPFILE;

ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_1=ENABLE;
ALTER SYSTEM SET LOG_ARCHIVE_DEST_STATE_2=ENABLE;
ALTER SYSTEM SET LOG_ARCHIVE_MAX_PROCESSES=30;
ALTER SYSTEM SET LOG_ARCHIVE_FORMAT='ora_%t_%s_%r.arc' SCOPE=SPFILE;
ALTER SYSTEM SET REMOTE_LOGIN_PASSWORDFILE=EXCLUSIVE SCOPE=SPFILE;

ALTER SYSTEM SET LOG_ARCHIVE_CONFIG='DG_CONFIG=(orat,orap,oras)';
ALTER SYSTEM SET FAL_CLIENT='orat';
ALTER SYSTEM SET FAL_SERVER='orap';
ALTER SYSTEM SET LOCAL_LISTENER='db3:1522';

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

CREATE TABLE TEST2 (C1 INT PRIMARY KEY, C2 CHAR(6));

INSERT INTO TEST2 VALUES (52, 'rap');
INSERT INTO TEST2 VALUES (56, 'cap');
COMMIT;
ALTER SYSTEM CHECKPOINT;
ALTER SYSTEM SWITCH LOGFILE;
ALTER SYSTEM archIVE LOG CURRENT;
SELECT * FROM TEST2;


#--------- Add to DataGuard Broker

dgmgrl sys/password as sysdba

DGMGRL> add database 'orat' as connect identifier is 'orat' maintained as physical;
Error: ORA-16698: LOG_ARCHIVE_DEST_n parameter set for object to be added
--- To resolve this error set below
--- No need to start the database post this setting
alter system set LOG_ARCHIVE_DEST_2='';

DGMGRL> add database 'orat' as connect identifier is 'orat' maintained as physical;
DGMGRL> show configuration;
DGMGRL> edit database orat set property 'LogXptMode'='sync';
DGMGRL> edit database orat set property staticconnectidentifier='(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(PORT=1522)(HOST=db3))(CONNECT_DATA=(SERVICE_NAME=ora)(INSTANCE_NAME=ora)(SERVER=DEDICATED)))';
DGMGRL> enable configuration;
DGMGRL> show configuration;
DGMGRL> edit database orat set property ApplyLagThreshold=0;
DGMGRL> edit database orat set property TransportLagThreshold=0;

DGMGRL> edit database orap set property FastStartFailoverTarget='oras,orat';
DGMGRL> edit database oras set property FastStartFailoverTarget='orap,orat';
DGMGRL> edit database orat set property FastStartFailoverTarget='orap,oras';

[oracle@db3 ~]$ cat $ORACLE_HOME/network/admin/tnsnames.ora - Same on all Nodes
orap =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = db1.db.com)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ora)))

oras =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = db2.db.com)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ora)))

orat =
  (DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = db2.db.com)(PORT = 1522))
    (CONNECT_DATA = (SERVER = DEDICATED)  (SERVICE_NAME = ora)))

nohup dgmgrl sys/password@orap "start observer file='$ORACLE_HOME/dbs/fsfo.dat'" -logfile $HOME/observer.log &
