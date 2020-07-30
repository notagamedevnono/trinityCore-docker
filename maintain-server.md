
To back your mysql database up, run

    docker exec -it trinity-mysql bash -c "mysqldump -u [admin-name] --password=[admin-password] auth --single-transaction --quick --lock-tables=false > /var/dbdumps/auth-$(date +%F).sql"
    docker exec -it trinity-mysql bash -c "mysqldump -u [admin-name] --password=[admin-password] characters --single-transaction --quick --lock-tables=false > /var/dbdumps/characters-$(date +%F).sql"
    docker exec -it trinity-mysql bash -c "mysqldump -u [admin-name] --password=[admin-password] world --single-transaction --quick --lock-tables=false > /var/dbdumps/world-$(date +%F).sql"

