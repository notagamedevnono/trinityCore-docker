# trinityCore-docker

This project contains build and deploy scripts to help you easily run the World of Warcraft [TrinityCore](https://www.trinitycore.org/) server in a Docker container. There are several other projects which containerize TrinityCore, this one is designed to be simple, both for building and running. Scripts/tips for running and maintaining your server and database are included. This project has been used to build and run a stable private service for almost two years. It is confirmeed working as far back as https://github.com/TrinityCore/TrinityCore/releases/tag/TDB335.20082, and as recently as https://github.com/TrinityCore/TrinityCore/releases/tag/TDB335.22011

- The script will build a TrinityCore 3.3.5 server container that includes _all files_ you need to run your server - sql scripts, client extractions, et al.
- All building, sql script managemant and WoW client data extraction is done for you from a single script.  
- The build script can be rerun to create new container versions as new tags are added to the 3.3.5 branch of TrinityCore. This project builds tags only (in this case the latest tag on the 3.3.5 branch) - building tags is considered best and accepted practice in software release.

This guide is for Docker and Linux only, if you want to host TrinityCore on Windows desktop, there are plenty of existing packs online for that.

## Why Containers? 

Running software in a container is far superior to installing software directly onto a machine as you can instantly and cleanly add/upgrade/remove a complex solution like TrinityCore without making a mess on your host device. All configuration is already done for you, all you need to do is spin the container up. 

## Requirements

- An _Ubuntu 20.04 LTS_ system, at least 100 gigs of free drive space, and as much memory and CPU as you can throw at it. If you have a Windows system you can run this in a VM in VirtualBox, HyperV etc. No other distro/version is supported because the build OS must match the Docker container OS. Ubuntu Server and Deskop Edition both work - ensure that `git`, `wget` and `curl` are installed. The build script checks and warns you if they are missing.
- `docker` installed - the standard version on Ubuntu 20.04 is fine. This script assumes you have Docker installed and working.
- A reference WoW 3.3.5 client - the Truewow version is guaranteed to work. Look around, you'll find it.

## Build

- Place your WoW client files in `~/wowClient` - Wow.exe should be in this folder. Once there, each build your run will clean and reuse these files, so leave them pristine if you plan on building new releases later.

- Clone this repo to your home folder @ `~/trinityCore-docker` 

      cd ~
      git clone https://github.com/notagamedevnono/trinityCore-docker.git
      cd trinityCore-docker
      
- Make the setup script executable

      chmod +x build.sh
  
  _WARNING_ : this script is going to change your system by installing all of Trinity's build prerequisites etc
      
- Run the build

      sudo ./build.sh
  
  If any required packages are missing, you should get some kind of error related to it.

- A few minutes later (about 12 on a 32 core Threadripper), your container will be done. A file dump of it will be placed in `~/trinityContainers` as a 7zip archive if you want to transfer it off your build system as a file. A private container repository is recommended if you want to push/pull your images via docker, but that is beyond the scope of this guide.

## Hosting your own server

### Requirements

- Any Linux system with Docker 19.x or better. TrinityCore won't work with a linked MySQL container on older versions of Docker.
- At least 1 CPU core, 2 GBs of RAM and 30 gigs of drive space. This container can be mounted on Linode's 2nd smallest VM type.
- 7zip installed

### Starting from scratch 

If you have no existing TrinityCore database to restore, see the [start from scratch](clean_server.md) guide.

### Upgrading an existing server

The TrinityCore team are excellent at maintaining backward compatibility of their project. I have been able to deploy new container versions simply by updating image tags in my docker-compose file and restarting the solution. I still suggest you back your data up first before upgrading. At the very least, bring all containers down and make a safety backup copy of your entire TrinityCore solution folder before updating the compose file - if something goes wrong you can continue running this.

### Restoring from backups

If you have existing TrinityCore database backups, see the [restore](restore_from_backups.md) guide.

### Backing up TrinityCore

Backing up TrinityCore in Docker is pretty straight forward. 

- Uploaded the included `backup.sh` script to your TrinityCore solution folder
- Run it

      sh ./backup.sh
      
   Backups will be written to the /dbdumps folder - three files are created : `auth.sql`, `characters.sql` and `world.sql`. You probably want to modify this backup script to do something more advanced, f.ex, zip all three files up together, name by date and upload the archive to S3 for storage.
   
