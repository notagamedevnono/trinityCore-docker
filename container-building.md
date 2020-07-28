# Build your container

This is the first step in building [TrinityCore](https://github.com/TrinityCore/TrinityCore) for Docker. It assumes you're starting from scratch. You'll end up with a container containing ONLY the binary executables needed to run TrinityCore

This guide reuses existing work. You should start with this [forum post](https://community.trinitycore.org/topic/13013-how-to-install-using-pre-compiled-packages/), which in turn will lead you to [this repo](https://github.com/Thulium-Drake/trinitycore-recipes), which in turn uses [this](https://github.com/mverboom/build) build script.

## Setup

The existing build projects I'm referencing use Debian 10, so that's what we're going to use. I rolled Debian Buster in VirtualBox, and gave it plenty (50gigs) of disk space as you're going to be working with a lot of files. I also needed to give it 8 gigs of memory, with less the build process failed.

You'll need an up-to-date version of Docker, don't use the standard version Buster installs as this has a DNS reverse lookup bug in docker-compose. I installed Docker 19.03.

Install Build using [its instructions](https://github.com/mverboom/build/blob/master/INSTALL.md). Do the example build to ensure that it works.

Clone the [trinitycore recipes project](https://github.com/Thulium-Drake/trinitycore-recipes) and move all files into your ~/recipes folder so the .recipe files are in /recipes folder. Open a terminal window and run 

    build -bp trinitycore-server3.3.5

At this point I got an error that build couldn't find a config for my os version. I editted trinitycore-server3.3.5.recipe and removed BUSTER from all [...] declarations, in this case REQUIRED and DEB. Rerun the above build command - note that it can take a while, depending on how many CPU cores you throw at it. When the build is done you'll have a file @

    ~/packages/trinitycore-server3.3.5-myorganisation_DATEHERE-1+deb10_amd64.deb
    
If you try to install this file in a docker container it will fail as it tries to set the server up with systemd, which you shouldn't have in a container. So, we're going to strip out the systemd stuff. In ~/packages

    mkdir extract
    dpkg-deb -R [trinitycore package name].deb extract

Edit extract/DEBIAN/conffiles remove

    /etc/systemd/system/trinitycore-authserver.service
    /etc/systemd/system/trinitycore-worldserver.service

Edit extract/DEBIAN/postinst remove

    # reload systemd
    systemctl daemon-reload

Delete this folder entirely

    extract/etc/systemd

Then repack with

    dpkg-deb -b extract trinitycore.repack.deb

Your repack file is now ready for docker. Move it to an empty folder and add the following Dockerfile to that folder. We use an empty folder so docker's build context is kept lean.

    FROM ubuntu:20.04

    # squelches tzdata's install prompt
    ENV DEBIAN_FRONTEND=noninteractive

    RUN apt-get update \
        && apt-get install -y wget \
        && apt-get install -y libboost-system1.67.0 \
        && apt-get install -y libboost-filesystem1.67.0 \
        && apt-get install -y libboost-thread1.67.0 \
        && apt-get install -y libboost-program-options1.67.0 \
        && apt-get install -y libboost-iostreams1.67.0 \
        && apt-get install -y libboost-regex1.67.0 \
        && apt-get install -y mariadb-client \
        && apt-get install -y libmariadbclient-dev \ 
        && wget -O /tmp/libreadline7.deb http://ftp.br.debian.org/debian/pool/main/r/readline/libreadline7_7.0-5_amd64.deb \
        && apt-get remove libreadline8 -y \
        && dpkg -i /tmp/libreadline7.deb \
        && rm /tmp/libreadline7.deb \
        && adduser -q -u 1000 trinitycore

    COPY ./trinitycore.repack.deb /tmp/trinitycore.repack.deb
    
    RUN dpkg -i /tmp/trinitycore.repack.deb \
        && rm /tmp/trinitycore.repack.deb
        
    ENV DEBIAN_FRONTEND=

    CMD ["/bin/bash", "-c", "while true ; sleep 5 ; done"]

Note

1 - we're building on Ubuntu20.x, I picked this mostly to play it safe, older versions or Debian might work too.
2 - I had to add libmariadbclient-dev, which is somehow not installed by the trinitycore installer
3 - TrintyCore has a hard dependency on libreadline7, but Ubuntu 20.04 has libreadline8, so I needed to remove one and force in the other.
4 - create the trinitycore user, trinity expects to have this user.
5 - after install explicitly downloaded deb packages, clean them up to save space
6 - the start command does nothing - the container will just idle. This is useful for debugging and setting up, we'll set the actual start commands using compose.
    
