export ORACLE_SID=oemrep
export ORACLE_UNQNAME=oemrep
export ORACLE_GLOBAL_NAME=oemrep.db.com
export ORACLE_BASE=/dbi/oracle/V19BaseDatabase
export ORACLE_HOME=/dbi/oracle/V19Database
export ORACLE_HOSTNAME=oem.db.com

sleep 2; /dbi/oracle/oemmw/bin/emctl stop oms
sleep 2; /dbi/oracle/oemagent/agent_inst/bin/emctl stop agent
sleep 2; /dbi/oracle/V19Database/bin/lsnrctl stop

sleep 2;

echo $ORACLE_SID
sqlplus '/as sysdba'<<!
show parameter db_name
select open_mode from v\$database ;
shut immediate
exit
!

echo '------------------------------------------------------------'
/dbi/oracle/V19Database/bin/lsnrctl status
echo '------------------------------------------------------------'
/dbi/oracle/oemmw/bin/emctl status oms
echo '------------------------------------------------------------'
/dbi/oracle/oemagent/agent_inst/bin/emctl status agent
echo '------------------------------------------------------------'
