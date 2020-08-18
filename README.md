# trinityCore-docker

TrinityCore in a docker container.

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
      
Your docker container will be placed in a zip file in ~/trinityContainers



