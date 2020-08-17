#!/bin/bash
SECONDS=0
CLIENT_FOLDER=$(readlink -f ../wowClient)
SRC_FOLDER=$(readlink -f ../trinitysrc)
# must be abs path, /opt/trinitycore is highly recommended, this will be the same path used in docker container
BUILD_FOLDER=/opt/trinitycore
CONTAINER_FOLDER=$(readlink -f ../trinityContainers)
BUILD_TAG=
BUILD_CORE_COUNT=6

# clean out target folder
rm -rf $BUILD_FOLDER
mkdir -p $BUILD_FOLDER
chown $USER -R $BUILD_FOLDER


CWD=$(pwd)


if [ ! -d $SRC_FOLDER ]; then
    git clone -b 3.3.5 git://github.com/TrinityCore/TrinityCore.git $SRC_FOLDER &&
    echo "clone to $SRC_FOLDER $CLIENT_FOLDER" 
else
    cd $SRC_FOLDER 
    git reset --hard &&
    git clean -f &&
    git pull &&
    cd -- 
fi

cd $SRC_FOLDER

if [ -z "$BUILD_TAG" ]; then
    BUILD_TAG=$(git describe --tags --abbrev=0) 
fi

git checkout $BUILD_TAG


# construct the name of the full database file for this tag
TAG_DATE=$(git log -1 --format=%ai $BUILD_TAG) &&
TAG_DATE=${TAG_DATE:0:10} &&
TAG_DATE=${TAG_DATE//-/_} &&
FULL_DATABASE_FRAGMENT="${BUILD_TAG}/TDB_full_world_${BUILD_TAG/TDB/}_${TAG_DATE}" &&


# install build prerequisites 
apt-get update &&
apt-get upgrade -y &&
apt-get install -y git clang cmake make gcc g++ libmariadbclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev libboost-all-dev=1.71.0.0ubuntu2 mariadb-server p7zip p7zip-full libmariadb-client-lgpl-dev-compat &&
update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 &&
update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang 100 &&


# configure and build
cd $SRC_FOLDER &&
rm -rf build &&
mkdir build &&
cd build &&
cmake ../ -DCMAKE_INSTALL_PREFIX=$BUILD_FOLDER &&
make -j $BUILD_CORE_COUNT &&
make install &&


# extract client data 
cd $CLIENT_FOLDER &&
rm -rf maps &&
${BUILD_FOLDER}/bin/mapextractor &&
mkdir ${BUILD_FOLDER}/data &&
cp -r dbc maps ${BUILD_FOLDER}/data &&

rm -rf vmaps &&
${BUILD_FOLDER}/bin/vmap4extractor &&
mkdir vmaps &&
${BUILD_FOLDER}/bin/vmap4assembler Buildings vmaps &&
cp -r vmaps ${BUILD_FOLDER}/data &&

rm -rf mmaps && 
mkdir mmaps &&
${BUILD_FOLDER}/bin/mmaps_generator &&
cp -r mmaps ${BUILD_FOLDER}/data &&


# get stock conf files
mv ${BUILD_FOLDER}/etc/worldserver.conf.dist ${BUILD_FOLDER}/etc/worldserver.conf &&
mv ${BUILD_FOLDER}/etc/authserver.conf.dist ${BUILD_FOLDER}/etc/authserver.conf &&


# get sql files
mkdir -p ${BUILD_FOLDER}/sql &&
cp -R $SRC_FOLDER/sql ${BUILD_FOLDER}/sql &&

wget https://github.com/TrinityCore/TrinityCore/releases/download/$FULLDATABASE.7z -O ${BUILD_FOLDER}/bin/fulldb.7z &&
7z x ${BUILD_FOLDER}/bin/fulldb.7z -O ${BUILD_FOLDER}/bin &&
rm ${BUILD_FOLDER}/bin/fulldb.7z &&


# build docker image
cd ${BUILD_FOLDER}
docker build -f ${CWD}/DockerFile -t trinitycore . &&
mkdir -p $CONTAINER_FOLDER &&
docker tag trinitycore:latest trinitycore:$BUILD_TAG &&
docker save trinitycore:$BUILD_TAG > ${CONTAINER_FOLDER}/trinitycore.tar &&
7z a ${CONTAINER_FOLDER}/trinitycore-docker.${BUILD_TAG}.$(date +\%F).7z ${CONTAINER_FOLDER}/trinitycore.tar &&
rm ${CONTAINER_FOLDER}/trinitycore.tar &&

DURATION=$SECONDS

echo "build done - time taken : $((($DURATION / 60) % 60)) minutes"