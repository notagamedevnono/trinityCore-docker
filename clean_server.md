### Starting a server from scratch

Your build script will have created a TrinityCore container zipped down to a file with a name like 

      trinitycore-docker.TDB335.20081.2020-08-20.7z 

In this example the container tag is `TDB335.20081`. Tags are like version numbers. Note the tag for the container you'll be deploying.

- Transfer your TrinityCore container zip to your Docker host server

- Unpack the docker container tar with
      
      7z x <zip name> 
  
- load the docker image from the tar file

      docker load -i trinitycore.tar
   
   You can delete the zip and tar now.
      
 - create a folder to host your TrinityCore solution in - this will contain your conf files, SQL data, everything your server needs will be in this one location.
 
 - Get the world and auth server config files at these paths
 
    https://github.com/TrinityCore/TrinityCore/blob/<TAG HERE!>/src/server/worldserver/worldserver.conf.dist
    https://github.com/TrinityCore/TrinityCore/blob/<TAG HERE!>/src/server/authserver/authserver.conf.dist
    
  replace <TAG HERE!> with your container tag (aka version). Save these files to your solution folder as worldserver.conf and authserver.conf
  
  - Edit worldserver.conf and authserver.conf as per your requirements - you use them to control server setup and behaviour. Check the official TrinityCore docs for info on configuring your server, but to get a basic setup running, and particularly with docker in mine, you should set the following 
  
      In worldserver.conf set
      
      - connection strings to databases to

            LoginDatabaseInfo     = "db;3306;root;root;auth"
            WorldDatabaseInfo     = "db;3306;root;root;world"
            CharacterDatabaseInfo = "db;3306;root;root;characters"
        
        "db" is the MySQL container id, "root" and "root" are the Mysql username and password, all three are set in docker-compose.yml

      - change the source directory to
      
            SourceDirectory = "/opt/trinitycore"

      - change the data directory to
      
            DataDir = "../data"
            
      - enable remote access so you can administer your server via telnet

            Ra.Enable = 1
          
      In authserver.conf set   
      
      - connection string 
      
            LoginDatabaseInfo = "db;3306;root;root;auth"
      
        `db`, `root` and `root` are the same as those set in woldserver.conf.
      
- upload the docker-compose.yml file in this repo to your solution folder.

- Start your docker-compose

      docker-compose up -d
  
  At this point the world and auth server containers will start, but they will not yet start TrinityCore, as their respective start commands are still commented out.
      
- Run the following commands to initialize your database      

      docker exec -it trinity-world bash -c "cp /opt/trinitycore/sql/create/create_mysql.sql /var/trinityscripts"
      docker exec -it trinity-db bash -c "mysql -u root -proot  < /var/trinityscripts/create_mysql.sql"
      
  This creates the databases needed by Trinitycore.    
    
- Shell into your world server container 

      docker exec -it trinity-world bash
   
   Now start the worldserver manually
   
      cd /opt/trinitycore/bin
      ./worldserver
      
   Give TrinityCore a minute to self-initialize its database. You'll eventually see a `TC>` prompt when it's ready. Create your GM account
   
      .account create YOURGMNAME YOURPASSWORD
      .account set gmlevel YOURGMNAME 3
    
    You need a GM account to telnet into the server. While you're here you can create other user accounts or do general Trinity house keeping. Exit worldserver and container with 
    
      CTRL+C
      exit
      
- Edit worldserver.conf again and disable console as you no longer need it

      Console.Enable = 0
      
   We do this so TrinityCore will run in "daemon" mode and stop flooding your logs with console input prompts.

- Add your realm IP to the auth database. Figure out your Docker host machine IP and then run

      docker exec -it trinity-db bash -c "mysql -u root -proot -D auth -e \"UPDATE realmlist SET address='YOUR-IP-HERE' \" "  
      
- Uncomment the two `command` lines in docker-compose.yml, and restart your solution
      
      docker-compose up -d --force-recreate

- Your TrinityCore server is ready to use.  For further admin telnet in to @ your Docker host IP and port 3443, use your GM credentials. Your GM credentials also allow you to log in with your WoW client.
