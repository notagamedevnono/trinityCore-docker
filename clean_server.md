### Starting a server from scratch

- Transfer your TrinityCore docker archive to your server. The archive file name contains the version tag for Trinity. Note this.
- Unpack with 
      
      7z x <archive name> 

- load the docker image from the resulting tar file

      docker load -i trinitycore.tar
      
 - create a folder to host your TrinityCore docker solution in
 - Get the world and auth server config files for your tag at these paths
 
    https://github.com/TrinityCore/TrinityCore/blob/<TAG HERE!>/src/server/worldserver/worldserver.conf.dist
    https://github.com/TrinityCore/TrinityCore/blob/<TAG HERE!>/src/server/authserver/authserver.conf.dist
    
  replace <TAG HERE!> with the tag of your build. Save these files to your trinitycore solution folder as worldserver.conf and authserver.conf
  
  - Edit worldserver.conf and authserver.conf as per your requirements. It is beyond the scope of this setup to explain the details of configuring TrinityCore, but there are some details which are pertinent for hosting docker
  
      In worldserver.conf set
      
      - connection strings to databases to

          LoginDatabaseInfo     = "db;3306;root;root;auth"
          WorldDatabaseInfo     = "db;3306;root;root;world"
          CharacterDatabaseInfo = "db;3306;root;root;characters"

      - change the source directory 
      
          SourceDirectory = "/opt/trinitycore"
          
      - enable remote access so you can administer your server via telnet

          Ra.Enable = 1
          
      In authserver.conf set   
      
      - LoginDatabaseInfo = "db;3306;root;root;auth"
      
- upload the docker-compose.yml file in this repo to that folder. Edit it, replace SQL credentials if you want, and <TAG-HERE!> with your current Trinitycore version.
- Start your docker-compose

      docker-compose up -d
      
- Run the following scripts to initialize your database      

      docker exec -it trinity-world bash -c "cp /opt/trinitycore/sql/create/create_mysql.sql /var/trinityscripts"
      docker exec -it trinity-db bash -c "mysql -u root -proot  < /var/trinityscripts/create_mysql.sql"
  
- Add your realm IP : TrinityCore requires that your server's IP is added to the realmlist table. Figure out what your Docker host machine IP is then run this

      docker exec -it trinity-db bash -c "mysql -u root -proot -D auth -e \"UPDATE realmlist SET address='YOUR-IP-HERE' \" "  
    
- Create a GM account - shell into your world server and start trinity manually

      docker exec -it trinity-world bash
      cd /opt/trinitycore/bin
      ./worldserver
      
   Trinity will self-init its database and wait for input from you. Create your GM account
   
      .account create YOURGMNAME YOURPASSWORD
      .account set gmlevel YOURGMNAME 3
    
    While you're here you can create other user accounts or do general Trinity house keeping. Exit worldserver and container with 
    
      CTRL+C
      exit
      
- Edit worldserver.conf again and disable console

      Console.Enable=0
      
   We do this so TrinityCore will run in "daemon" mode,  if we don't the console prompt waiting for user input will flood your docker logs
   
- Uncomment start `command` lines in docker-compose.yml
- Restart your solution
      
      docker-compose down
      docker-compose up -d
      
- Your TrinityCore server is ready to use. For further admin, telnet in to @ your Docker host IP and port 3443, use your GM credentials.
