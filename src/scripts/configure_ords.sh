# Make sure to set ORDS_CONFIG environment variable
# or include --config path/to/config

# Add database user config for PDB lifecycle management
ords config set db.cdb.adminUser "C##DBAPI_CDB_ADMIN as SYSDBA"
ords config secret db.cdb.adminUser.password

# Create ORDS user for authentication
ords config user add ordspdbadmin "SQL Administrator, System Administrator"
