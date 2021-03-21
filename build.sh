#!/bin/bash

##############################################################################################################
# This script will build TrinityCore from source, extract all data and pack all required binaries, sql files
# and client data into a docker image that can be instantly mounted to spawn a TrinityCore server. Please see
# accomanying README.md for details on how to run.



##############################################################################################################
# Set up some vars to control where/how we work. You don't need to do any here, default values will work fine.

# force exit if anything fails
set -e

# repo/branch to fetch server source from. Must be trinitycore or fork thereof. 
# To build Lich King use repo https://github.com/TrinityCore/TrinityCore, branch 3.3.5
# To build Cataclym use repo https://github.com/The-Cataclysm-Preservation-Project, branch master
REPO=https://github.com/The-Cataclysm-Preservation-Project
BRANCH=master

# this should be set to "authserver" for Lich King, and "bnetserver" for anything after
AUTH_SERVER=authserver

# used to time build 
SECONDS=0

# path to WoW 3.3.5 client
CLIENT_FOLDER=$(readlink -f ../wowClient)

# path trinity source will be checked out to
SRC_FOLDER=$(readlink -f ../trinitysrc)

# path trinity will be built to. Must be abs path, /opt/trinitycore is highly recommended, this will be the 
# same path used in docker container
BUILD_FOLDER=/opt/trinitycore

# path container zips will be placed. These can be transferred to other systems to mount. Assuming you're not 
# going to push a 6+gig docker image to the official docker hub, and you probably don't have a private 
# container repo, so we're transferring images as bin files
CONTAINER_FOLDER=$(readlink -f ../trinityContainers)

# overbook threads to use for build. You want to build at full tilt, it speeds the build up tremendously
BUILD_THREAD_COUNT=18

# if you want to force this script to build a specific tag, set it here. Use tags only, don't built arbitrary 
# hashes, this script hasn't been tested to work with hashes
BUILD_TAG=

# if you want to rebuild and skip compilation and client extraction, use "--partial" switch. This is for 
# dev/testing, so don't use this unless you know what you're doing
FULL_BUILD=1
while [ -n "$1" ]; do 
    case "$1" in
    -p|--partial) FULL_BUILD=0 ;;
    esac 
    shift
done

# these should always be 1, unless you're debugging this script and want to easily bypass time-consuming 
# stages that you know have already passed
BUILD_BINARIES=1
CLEAN_CONTENT=1
EXTRACT_MAPS=1
EXTRACT_VMAPS=1
ASSEMBLE_VMAPS=1
GENERATE_MMAPS=1
BUILD_CONTAINER=1
ARCHIVE_CONTAINER=1

# ensure script was run as sudo
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


##############################################################################################################
# try to test as much as possible before running script so we can catch missing/broken things

# ensure that docker is available
echo "doing docker version check ..."
docker --version

echo "doing git version check ..."
git --version

echo "testing wget"
wget --help

echo "testing curl"
curl --version


##############################################################################################################
# clean out build target folder entirely. we're building into /opt/trinitycore so chown it. We build to 
# /opt/trinitycore because trinitycore's make hardcodes its path internally. We want our docker bins to live in 
# /opt/trinitycore, so we need to build there
if [ $BUILD_BINARIES -eq 1 ]; then
    rm -rf $BUILD_FOLDER
fi
    
mkdir -p $BUILD_FOLDER
chown $USER -R $BUILD_FOLDER

# capture this script's path so we can come back here later to fetch our Dockerfile
CWD=$(pwd)

# clone or pull trinity src
if [ ! -d $SRC_FOLDER ]; then
    git clone $REPO $SRC_FOLDER 
    cd --
fi

# make sure we have latest changes on target branch (if we're re-building existing checkout)
cd $SRC_FOLDER
git reset --hard
git clean -f
git checkout $BRANCH # do this to re-attach to branch 
git pull
cd -- 


# figure out the latest tag in trinity src. We build tags and tags only, because that's how civilized people 
# distribute software
cd $SRC_FOLDER
if [ -z "$BUILD_TAG" ]; then
    BUILD_TAG=$(git describe --tags --abbrev=0) 
fi


# Now that we have the tag, check it out
git checkout $BUILD_TAG


# construct the name of the full database file for this tag. Trinity expects this honking big sql file to be 
# placed in its /bin folder
TAG_DATE=$(git log -1 --format=%ai $BUILD_TAG)
TAG_DATE=${TAG_DATE:0:10}
TAG_DATE=${TAG_DATE//-/_}
FULL_DATABASE_FRAGMENT="${BUILD_TAG}/TDB_full_world_${BUILD_TAG/TDB/}_${TAG_DATE}"


# install build prerequisites. This is an unholy mess that's going to constantly shift as Ubuntu 20.04 gets 
# maintainance patches, but we'll hopefully stay sync with our Ubuntu 20.04 docker image by buiding at the 
# same time as updating the host. Fingers crossed.
apt-get update
apt-get upgrade -y
apt-get install -y git clang cmake make gcc g++ libmariadbclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev=1.71.0.0ubuntu2 mariadb-server p7zip p7zip-full libmariadb-client-lgpl-dev-compat
update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100
update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100

# configure and build
cd $SRC_FOLDER
if [ $BUILD_BINARIES -eq 1 ]; then
    rm -rf build
fi

mkdir -p build
cd build

if [ $BUILD_BINARIES -eq 1 ]; then
    cmake ../ -DCMAKE_INSTALL_PREFIX=$BUILD_FOLDER
    make -j $BUILD_THREAD_COUNT
    make install
fi

# clean out any trinity extract stuff from wowClient folder, if we don't do this trinity extract will complain 
# about contamination
cd $CLIENT_FOLDER
if [ $CLEAN_CONTENT -eq 1 ]; then
    rm -rf Buildings
    rm -rf Cameras
    rm -rf dbc
    rm -rf maps
    rm -rf mmaps
    rm -rf vmaps
fi

# extract data from WoW client, this is where the real time penalty hits
if [ $EXTRACT_MAPS -eq 1 ]; then
    ${BUILD_FOLDER}/bin/mapextractor
fi
    
mkdir -p ${BUILD_FOLDER}/data
cp -r dbc maps ${BUILD_FOLDER}/data



if [ $EXTRACT_VMAPS -eq 1 ]; then
    ${BUILD_FOLDER}/bin/vmap4extractor
fi    

mkdir -p vmaps

if [ $ASSEMBLE_VMAPS -eq 1 ]; then
    ${BUILD_FOLDER}/bin/vmap4assembler Buildings vmaps
fi
    
cp -r vmaps ${BUILD_FOLDER}/data

mkdir -p mmaps
if [ $GENERATE_MMAPS -eq 1 ]; then
    ${BUILD_FOLDER}/bin/mmaps_generator
fi    
cp -r mmaps ${BUILD_FOLDER}/data


# get stock conf files and put them where bins expect them to be
cp ${BUILD_FOLDER}/etc/worldserver.conf.dist ${BUILD_FOLDER}/etc/worldserver.conf
cp ${BUILD_FOLDER}/etc/${AUTH_SERVER}.conf.dist ${BUILD_FOLDER}/etc/${AUTH_SERVER}.conf

# get sql files and put them in /sql folder
mkdir -p ${BUILD_FOLDER}/sql
cp -R $SRC_FOLDER/sql ${BUILD_FOLDER}

# download that honking big full database file and unpack it to /bin
wget ${REPO}/releases/download/${FULL_DATABASE_FRAGMENT}.7z -O ${BUILD_FOLDER}/bin/fulldb.7z
# -aoa = overwrite everything with prompt
7z x ${BUILD_FOLDER}/bin/fulldb.7z -o${BUILD_FOLDER}/bin -aoa
rm ${BUILD_FOLDER}/bin/fulldb.7z

# build docker image using the Dockerfile in this repo. 
if [ $BUILD_CONTAINER -eq 1 ]; then
    cd ${BUILD_FOLDER}
    docker build -f ${CWD}/DockerFile -t trinitycore .

    # Use docker save to pack our container to a tar file, then zip that because it's giant AF and we will almost 
    # certainly want to transfer it to another server to host. Note that the container has already been tagged to 
    # match the TrinityCore tag we built from.
    mkdir -p $CONTAINER_FOLDER
    docker tag trinitycore:latest trinitycore:$BUILD_TAG
    docker save trinitycore:$BUILD_TAG > ${CONTAINER_FOLDER}/trinitycore.tar
fi


# stage conf files to container folder, then zip everything up
if [ $ARCHIVE_CONTAINER -eq 1 ]; then
    cp ${BUILD_FOLDER}/etc/worldserver.conf ${CONTAINER_FOLDER}/worldserver.conf
    cp ${BUILD_FOLDER}/etc/${AUTH_SERVER}.conf ${CONTAINER_FOLDER}/${AUTH_SERVER}.conf
    7z a ${CONTAINER_FOLDER}/trinitycore-docker.${BUILD_TAG}.$(date +\%F).7z ${CONTAINER_FOLDER}/trinitycore.tar ${CONTAINER_FOLDER}/worldserver.conf ${CONTAINER_FOLDER}/${AUTH_SERVER}.conf
    
    # clean up container folder, it should contain only 7z files
    rm ${CONTAINER_FOLDER}/*.tar
    rm ${CONTAINER_FOLDER}/*.conf
fi


# phew, we're done
DURATION=$SECONDS
echo "build done - time taken : $((($DURATION / 60) % 60)) minutes"
