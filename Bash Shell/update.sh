#!/usr/bin/env bash
#! /bin/bash

# variables
DIRECTORY=build

#functions
log () {
   echo
   echo "============================================="
   echo "    $1"
   echo "============================================="
   echo
}

log "Updating Provider Services"

if [ -d "$DIRECTORY" ]; then
  log "1 - Stopping current Instances...";
  cd $DIRECTORY;
  docker-compose -f docker-compose.yml down
  cd ..
  rm -rf $DIRECTORY
fi

log "2 - Downloading new version...";

wget --header="Private-Token:3auyce_AjTBZE69KK8UA" -O build.zip https://git.kaiostech.com/itriad/kaios-providers/-/jobs/artifacts/master/download?job=dist && unzip build.zip && rm build.zip

log "3 - Starting new services";

cd build
docker-compose -f docker-compose.yml up -d
cd ..
echo
