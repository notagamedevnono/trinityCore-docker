# this backups your trinitycore db while its running
set -e

echo "dumping auth"
docker exec trinity-mysql bash -c "mysqldump -u root --password=root auth --single-transaction --quick --lock-tables=false > /var/dbdumps/auth.sql" 

echo "dumping characters"
docker exec trinity-mysql bash -c "mysqldump -u root --password=root characters --single-transaction --quick --lock-tables=false > /var/dbdumps/characters.sql" 

echo "dumping world"
docker exec trinity-mysql bash -c "mysqldump -u root --password=root world --single-transaction --quick --lock-tables=false > /var/dbdumps/world.sql" 
