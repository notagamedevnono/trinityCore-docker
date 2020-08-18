# trinityCore-docker

- A full build system for TrinityCore 3.3.5
- Requires minimal setup, does _everything_ for you.
- Produces local binaries and a fully-featured docker container that can be easily transferred to other systemms and mounted there.
- Can be run continuously to create new containers based on the latest tag in the 3.3.5 branch.
- Includes a handy SQL backup script that will back your Mysql container data up.
- Includes instructions to mount a new server, or restore a server from SQL backups.

## Requires

- An Ubuntu 20.04 LTS system, at least 150 gigs of free drive space, and as much memory and cpu as you can throw at it.
- Docker 19.x preinstalled
- Your legally-purchased WoW 3.3.5 client in a folder ~/wowClient

## How to

- clone this repo to your home folder
- cd /trinityCore-docker
- Make the setup script executable

      chmod +x build.sh
  
  Warning : this script is going to install all of Trinity's build prerequisites to your system
      
- Run build

      sudo ./build.sh
  
- Your build binaries will be placed in /opt/trinitycore
- Your docker container will be placed in a zip file in ~/trinityContainers



