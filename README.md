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
