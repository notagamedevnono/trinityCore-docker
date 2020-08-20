#!/bin/bash

##############################################################################################################
# This script will build TrinityCore from source, extract all data and pack all required binaries, sql files
# and client data into a docker image that can be instantly mounted to spawn a TrinityCore server. Please see
# accomanying README.md for details on how to run.



##############################################################################################################
# Set up some vars to control where/how we work. You don't need to do any here, default values will work fine.

# force exit if anything fails
set -e

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

# number of threads to use for build. You want to build at full tilt, it speeds the build up tremendously
BUILD_THREAD_COUNT=18

# if you want to force this script to build a specific tag, set it here. Use tags only, don't built arbitrary 
# hashes, this script hasn't been tested to work with hashes
BUILD_TAG=


##############################################################################################################
# clean out build target folder entirely. we're building into /opt/trinitycore so chown it. We build to 
# /opt/trinitycore because trinitycore's make hardcodes its path internally. We want our docker bins to live in 
# /opt/trinitycore, so we need to build there
rm -rf $BUILD_FOLDER
mkdir -p $BUILD_FOLDER
chown $USER -R $BUILD_FOLDER

# capture this script's path so we can come back here later to fetch our Dockerfile
CWD=$(pwd)

# clone or pull trinity src
if [ ! -d $SRC_FOLDER ]; then
    git clone -b 3.3.5 git://github.com/TrinityCore/TrinityCore.git $SRC_FOLDER 
else
    cd $SRC_FOLDER
    git checkout 3.3.5
    git reset --hard
    git clean -f
    git pull
    cd -- 
fi

cd $SRC_FOLDER

# figure out the latest tag in trinity src. We build tags and tags only, because that's how civilized people 
# distribute stuff
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
rm -rf build
mkdir -p build
cd build
cmake ../ -DCMAKE_INSTALL_PREFIX=$BUILD_FOLDER
make -j $BUILD_THREAD_COUNT
make install


# clean out any trinity extract stuff from wowClient folder, if we don't do this trinity extract will complain 
# about contamination
cd $CLIENT_FOLDER
rm -rf Buildings
rm -rf Cameras
rm -rf dbc
rm -rf maps
rm -rf mmaps
rm -rf vmaps


# extract data from WoW client, this is where the real time penalty hits
${BUILD_FOLDER}/bin/mapextractor
mkdir -p ${BUILD_FOLDER}/data
cp -r dbc maps ${BUILD_FOLDER}/data

${BUILD_FOLDER}/bin/vmap4extractor
mkdir -p vmaps
${BUILD_FOLDER}/bin/vmap4assembler Buildings vmaps
cp -r vmaps ${BUILD_FOLDER}/data

mkdir -p mmaps
${BUILD_FOLDER}/bin/mmaps_generator
cp -r mmaps ${BUILD_FOLDER}/data


# get stock conf files and put them where bins expect them to be
mv ${BUILD_FOLDER}/etc/worldserver.conf.dist ${BUILD_FOLDER}/etc/worldserver.conf
mv ${BUILD_FOLDER}/etc/authserver.conf.dist ${BUILD_FOLDER}/etc/authserver.conf


# get sql files and put them in /sql folder
mkdir -p ${BUILD_FOLDER}/sql
cp -R $SRC_FOLDER/sql ${BUILD_FOLDER}

# download that honking big full database file and unpack it to /bin
wget https://github.com/TrinityCore/TrinityCore/releases/download/${FULL_DATABASE_FRAGMENT}.7z -O ${BUILD_FOLDER}/bin/fulldb.7z
# -aoa = overwrite everything with prompt
7z x ${BUILD_FOLDER}/bin/fulldb.7z -o${BUILD_FOLDER}/bin -aoa
rm ${BUILD_FOLDER}/bin/fulldb.7z

# build docker image using the Dockerfile in this repo. 
cd ${BUILD_FOLDER}
docker build -f ${CWD}/DockerFile -t trinitycore .

# Use docker save to pack our container to a tar file, then zip that because it's giant AF and we will almost 
# certainly want to transfer it to another server to host. Note that the container has already been tagged to 
# match the TrinityCore tag we built from.
mkdir -p $CONTAINER_FOLDER
docker tag trinitycore:latest trinitycore:$BUILD_TAG
docker save trinitycore:$BUILD_TAG > ${CONTAINER_FOLDER}/trinitycore.tar
7z a ${CONTAINER_FOLDER}/trinitycore-docker.${BUILD_TAG}.$(date +\%F).7z ${CONTAINER_FOLDER}/trinitycore.tar
rm ${CONTAINER_FOLDER}/trinitycore.tar

# phew, we're done
DURATION=$SECONDS
echo "build done - time taken : $((($DURATION / 60) % 60)) minutes"
