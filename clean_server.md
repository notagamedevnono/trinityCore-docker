### Starting a server from scratch

See the [readme.md](-/README.md) for Docker host requirements. Your TrinityCore container will be zipped down to file based with a name like 

      trinitycore-docker.TDB335.20081.2020-08-20.7z 

In this example the tag is `TDB335.20081`. Tags are like version numbers. Note the tag for the container zip you'll be deploying.

- Transfer your TrinityCore container zip to your Docker host server
- Unpack with 
      
      7z x <zip name> 

- load the docker image from the resulting tar file

      docker load -i trinitycore.tar
   
   You can delete the zip and tar now.
      
 - create a folder to host your TrinityCore solution in - this will contain your conf files, SQL data etc.
 - Get the world and auth server config files at these paths
 
    https://github.com/TrinityCore/TrinityCore/blob/<TAG HERE!>/src/server/worldserver/worldserver.conf.dist
    https://github.com/TrinityCore/TrinityCore/blob/<TAG HERE!>/src/server/authserver/authserver.conf.dist
    
  replace <TAG HERE!> with the tag of your build. Save these files to your solution folder as worldserver.conf and authserver.conf
  
  - Edit worldserver.conf and authserver.conf as per your requirements. It is beyond the scope of this document to explain the details of configuring TrinityCore, but there are some details which are pertinent for running TrinityCore in docker
  
      In worldserver.conf set
      
      - connection strings to databases to

            LoginDatabaseInfo     = "db;3306;root;root;auth"
            WorldDatabaseInfo     = "db;3306;root;root;world"
            CharacterDatabaseInfo = "db;3306;root;root;characters"
        
        "db" in this case is the MySQL container id, "root" and "root" are the Mysql username and password, all three are defined in docker-compose.yml

      - change the source directory to
      
            SourceDirectory = "/opt/trinitycore"

      - change the data directory to
      
            DataDir = "../data"
            
      - enable remote access so you can administer your server via telnet

            Ra.Enable = 1
          
      In authserver.conf set   
      
      - connection strings 
      
            LoginDatabaseInfo = "db;3306;root;root;auth"
      
        `db`, `root` and `root` are the same as those set in woldserver.conf.
      
- upload the docker-compose.yml file in this repo to your solution folder.

- Start your docker-compose

      docker-compose up -d
  
  At the this point the world and auth server contains will start, but they will not yet start Trinitycore, as those commands are still commented out.
      
- Run the following scripts to initialize your database      

      docker exec -it trinity-world bash -c "cp /opt/trinitycore/sql/create/create_mysql.sql /var/trinityscripts"
      docker exec -it trinity-db bash -c "mysql -u root -proot  < /var/trinityscripts/create_mysql.sql"
      
  This creates empty databases needed by Trinitycore.    
    
- Shell into your world server and start trinity manually

      docker exec -it trinity-world bash
      cd /opt/trinitycore/bin
      ./worldserver
      
   Give TrinityCore a minute to self-initialize its database. You'll eventually see a `TC>` prompt when it's ready. Create your GM account
   
      .account create YOURGMNAME YOURPASSWORD
      .account set gmlevel YOURGMNAME 3
    
    While you're here you can create other user accounts or do general Trinity house keeping. Exit worldserver and container with 
    
      CTRL+C
      exit
      
- Edit worldserver.conf again and disable console

      Console.Enable = 0
      
   We do this so TrinityCore will run in "daemon" mode,  if we don't the console prompt waiting for user input will flood your docker logs

- Add your realm IP : TrinityCore requires that your server's IP is added to the realmlist table. Figure out what your Docker host machine IP is then run this

      docker exec -it trinity-db bash -c "mysql -u root -proot -D auth -e \"UPDATE realmlist SET address='YOUR-IP-HERE' \" "  
      
- Uncomment the two `command` lines in docker-compose.yml, and restart your solution
      
      docker-compose up -d --force-recreate

- Your TrinityCore server is ready to use. For further admin, telnet in to @ your Docker host IP and port 3443, use your GM credentials.
