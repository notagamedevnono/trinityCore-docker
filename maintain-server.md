
To back your mysql database up, run

    docker exec -it trinity-mysql bash -c "mysqldump -u [admin-name] --password=[admin-password] auth --single-transaction --quick --lock-tables=false > /var/dbdumps/auth-$(date +%F).sql"
    docker exec -it trinity-mysql bash -c "mysqldump -u [admin-name] --password=[admin-password] characters --single-transaction --quick --lock-tables=false > /var/dbdumps/characters-$(date +%F).sql"
    docker exec -it trinity-mysql bash -c "mysqldump -u [admin-name] --password=[admin-password] world --single-transaction --quick --lock-tables=false > /var/dbdumps/world-$(date +%F).sql"

To restore your database from a given day run

- drop existing databases if they exist
- create auth, character and world ones by name

    docker exec -it trinity-mysql bash -c "mysql -u [admin-name] --password=[admin-password] world < /var/dbdumps/world-$(date +%F).sql"
    docker exec -it trinity-mysql bash -c "mysql -u [admin-name] --password=[admin-password] auth < /var/dbdumps/auth-$(date +%F).sql"
    docker exec -it trinity-mysql bash -c "mysql -u [admin-name] --password=[admin-password] character < /var/dbdumps/character-$(date +%F).sql"
