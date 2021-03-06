# trinityCore-docker

This project contains a build script to help you easily build [TrinityCore](https://www.trinitycore.org/) server in a Docker container. There are several other projects out there which containerize TrinityCore, but I wanted to make one that was really simple, both for building and running. I also included scripts/tips for running and maintaining your server, including database backup and restore. These are based off my own server's scripts.

- The script will build a self-contained TrinityCore 3.3.5 server container- all sql scripts and WoW client data extraction is done for you. 
- Once built, your container can be mounted as-is to spin up a Trinitycore server on any Linux machine - create new servers, multiple servers, transfers servers to other machines, etc.
- The build script can be rerun to create new container versions as new tags are added to the 3.3.5 branch of TrinityCore. This scripts always builds the last tag on that branch.

## Build 

### Requirements

- An _Ubuntu 20.04 LTS_ system, at least 100 gigs of free drive space, and as much memory and CPU as you can throw at it. VMs works fine. No other distro/version is supported because the build OS must match the Docker container OS. Ubuntu Server Edition works out-of-the box, Deskop Edition will require `git`, `wget` and `curl`.
- `docker` installed.
- A totally legitimate, non-dubiously-procurred WoW 3.3.5 client.

### How to

- Place your WoW client files @ `~/wowClient`. Once there, each build your run will clean and read it.

- Clone this repo to your home folder @ `~/trinityCore-docker` then

      cd ./trinityCore-docker
      
- Make the setup script executable

      chmod +x build.sh
  
  _WARNING_ : this script is going to change your system by installing all of Trinity's build prerequisites etc
      
- Run the build

      sudo ./build.sh
  
- A few minutes later (about 12 on a 32 core Threadripper), your container will be placed in `~/trinityContainers` as a 7zip archive. The build is done. 

## Create a server

### Requirements

- Any Linux system with Docker 19.x or better. TrinityCore won't work with a linked MySQL container on older versions of Docker.
- At least 1 CPU core, 2 GBs of RAM and 30 gigs of drive space. This container can be mounted on Linode's 2nd smallest VM type.
- 7zip installed

### Starting from scratch 

If you have no existing TrinityCore database to restore, see the [start from scratch](clean_server.md) guide.

### Restoring from backups

If you have existing TrinityCore database backups, see the [restore](restore_from_backups.md) guide.

### Backing up TrinityCore

Backing up TrinityCore in Docker is pretty straight forward. 

- Uploaded the included `backup.sh` script to your TrinityCore solution folder
- Run it

      sh ./backup.sh
      
   Backups will be written to the /dbdumps folder - three files are created : `auth.sql`, `characters.sql` and `world.sql`. You probably want to modify this backup script to do something more advanced, f.ex, zip all three files up together, name by date and upload the archive to S3 for storage.
   
