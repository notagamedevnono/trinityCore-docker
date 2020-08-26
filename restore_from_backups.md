# Restoring TrinityCore from backups

- If you're starting a new server from scratch but have a data to restore
 
      7z x <your archive name>.7z
      cd <your archive name>
      docker load -i trinitycore.tar
      
      docker-compose up -d
      
      docker exec -it trinity-world bash -c "cp /opt/trinitycore/sql/create/create_mysql.sql /var/trinityscripts"
      docker exec -it trinity-db bash -c "mysql -u root -proot  < /var/trinityscripts/create_mysql.sql"      
  
      
- else if you have existing data and want to completely overrwrite, Put your TrinityCore docker-compose solution in "idle" mode by commenting out the world and auth server `command` lines in `docker-compose.yml` and restarting with

      docker-compose up -d --force-recreate
  
- Destroy any existing TrinityCore data if any

      docker exec -it trinity-world bash -c "cp /opt/trinitycore/sql/create/drop_mysql.sql /var/trinityscripts"
      docker exec -it trinity-world bash -c "cp /opt/trinitycore/sql/create/create_mysql.sql /var/trinityscripts"
      docker exec -it trinity-db bash -c "mysql -u root -proot  < /var/trinityscripts/drop_mysql.sql"
      docker exec -it trinity-db bash -c "mysql -u root -proot  < /var/trinityscripts/create_mysql.sql"

- place your backup files in the `dbrestore` directory in your TrinityCore solution folder - you should have `auth.sql`, `world.sql` and `characters.sql`.

- Run the following from any terminal 

      docker exec -it trinity-db bash -c "mysql -u root -proot --database="auth"  < /var/dbrestore/auth.sql"
      docker exec -it trinity-db bash -c "mysql -u root -proot --database="characters"  < /var/dbrestore/characters.sql"
      docker exec -it trinity-db bash -c "mysql -u root -proot --database="world"  < /var/dbrestore/world.sql"
      
- Re-enbale the two `command` lines in `docker-compose.yml` and restart

      docker-compose up -d --force-recreate

