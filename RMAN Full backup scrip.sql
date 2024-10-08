## RMAN Script to backup primary database for standby

    CMD - mkdir -p /backup/oracle
    CMD - chown -Rf oracle:oinstall /backup/

mkdir -p /backup/oracle
mkdir -p /backup/oracle/prod/adump
    
Oracle$ rman target /
    
rman target=/ nocatalog <<EOF
run {
    sql "alter system archive log current";
    allocate channel ch1 type disk format '/backup/oracle/PROD_bkp_standby_%U';
    backup as compressed backupset database plus archivelog;
    backup current controlfile for standby;
    sql "alter system archive log current";
}
exit;
EOF

## copy backup data on standby

rman - duplicate target database for standby nofilenamecheck;
