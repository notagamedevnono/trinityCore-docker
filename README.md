# trinityCore-docker

- A full build system for TrinityCore 3.3.5
- Requires minimal setup, does _everything_ for you.
- Produces local binaries and a fully-featured docker container that can be easily transferred to other systems and mounted there.
- Can be run continuously to create new containers based on the latest tag in the 3.3.5 branch.
- Includes a handy SQL backup script that will back your Mysql container data up.
- Includes instructions to mount a new server, or restore a server from SQL backups.

## Build 

### Requires

- An Ubuntu 20.04 LTS system, at least 150 gigs of free drive space, and as much memory and CPU as you can throw at it. VirtualBox works fine.
- Docker 19.x or better preinstalled
- Your legally-purchased WoW 3.3.5 client in your hoome folder @ ~/wowClient

### How to

- clone this repo to your home folder
- cd ./trinityCore-docker
- Make the setup script executable

      chmod +x build.sh
  
  Warning : this script is going to change your system by installing all of Trinity's build prerequisites
      
- Run build

      sudo ./build.sh
  
- Your build binaries will be placed in /opt/trinitycore
- Your docker container will be placed in a zip file in ~/trinityContainers

## Running Trinitycore in docker

### Requires

- Litereally any Linux system that can run Docker 19.x or better
- 7zip installed
- 1 CPU core
- At least 2 gigs of RAM
- About 30 gigs of drive space to be safe

### Starting from scratch 

If you have no existing TrinityCore database to restore, see the [start from scratch](clean_server.md) guide.
