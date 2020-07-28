## Running a server

This is step 3 of the TrinityCore setup. You'll need a trinitycore docker image, and the trinitycore data extract.

On your host  machine, create folder to contain all your TrinityCore files - /srv/trinitycore for example. In this folder create a docker-compose.yml and paste the following into it.

    version: "3"
    services:
    
        db:
            image: mariadb:10.5.1
            container_name: trinity-mysql
            volumes:
                - ./mysql:/var/lib/mysql
                - ./createtrinity.sql:/var/createtrinity.sql
                - /etc/localtime:/etc/localtime:ro
            ports:
            - 3306:3306
            expose:
            - '3306'
            environment:
                - MYSQL_ROOT_PASSWORD=root   
                - MYSQL_PASSWORD=root     # yeah you probably want to change this
            restart: unless-stopped
            networks:
                - trinity_network

        world:
            image: trinitycore:latest
            container_name: worldserver
            ports:
            - 8085:8085
            - 7878:7878
            - 3443:3443 # RA access
            volumes:
                - ./worldserver.conf:/opt/trinitycore/etc/worldserver.conf
                - ./data:/opt/trinitycore/data
                # sql scripts should be distributed as part of the debian package. TODO.
                - ./TDB_full_world_335.20071_2020_07_15.sql:/opt/trinitycore/bin/TDB_full_world_335.20071_2020_07_15.sql
                - ./sql:/opt/trinitycore/sql
            depends_on:
            - db
            restart: unless-stopped
            command: /bin/sh -c  "cd /opt/trinitycore/bin && ./worldserver"
            networks:
                - trinity_network

        auth:
            image: trinitycore:latest
            container_name: authserver
            ports:
            - 3724:3724
            volumes:
                - ./authserver.conf:/opt/trinitycore/etc/authserver.conf
            depends_on:
            - world
            - db
            #restart: unless-stopped
            command: /bin/sh -c  "cd /opt/trinitycore/bin && ./authserver"
            networks:
                - trinity_network
                
    networks:

        trinity_network:
            driver: bridge

Don't fire this up yet.

## initialize the database

If you're doing a clean install with no existing data, you'll need to initialize your database first. 

    docker-compose up -d
    
This will start all 3 containrs but only mariadb will run, the others will fail. Run

    docker exec -it trinity-mysql bash -c "mysql -u root -proot < /opt/trinitycore/sql/create_mysql.sql"

## continuing ...    

- Download the /sql scripts folder from  https://github.com/TrinityCore/TrinityCore/tree/3.3.5/sql
- Download and extract TDB_full_world_335.20071_2020_07_15.sql from https://github.com/TrinityCore/TrinityCore/releases/download/TDB335.20071/TDB_full_world_335.20071_2020_07_15.7z
- copy a worldserver.conf and authserver.conf file from https://github.com/TrinityCore/TrinityCore/blob/3.3.5/src/server/worldserver/worldserver.conf.dist and https://github.com/TrinityCore/TrinityCore/blob/3.3.5/src/server/authserver/authserver.conf.dist
- edit authserver.conf 

    - replace 127.0.0.1 with the database container name "db", and change connection credentials to whatever you're using
    
        LoginDatabaseInfo = "db;3306;root;root;auth"
        
- edit worldserver.conf

    - replace 127.0.0.1 with "db" and whatever sql credentials you're using
    
        LoginDatabaseInfo     = "db;3306;root;root;auth"
        WorldDatabaseInfo     = "db;3306;root;root;world"
        CharacterDatabaseInfo = "db;3306;root;root;characters"
    
    - change the source directory
    
        SourceDirectory  = "/opt/trinitycore"
        
    - disable console to prevent your docker logs from flooding with empty console prompts
    
        Console.Enable = 0
        
    - enable remote access
    
        Ra.Enable = 1
        
## initializing an admin user

Oh wait, you're running on a clean install? Well, we still have some work to do.
- edit docker-compose.yml, disable CMD for worldserver so the container idles
- edit worldserver.conf and re-enable console
- docker-compose up 
- docker exec -it worldserver bash
- /opt/trinitycore/bin/worldserver to start srver
- .account create yourname yourpassword
- .account set gmlevel yourname 4
- exit
- docker-compose down, re-enable cmd for worldserver in docker-compose, disable console in worldserver.conf. You can now telnet in to your server your gm account
