#!/bin/bash

COMMAND=$1

function usage() {
  echo "test.sh <start|stop>"
}

if [ -z $COMMAND ]; then
   usage
   exit 1
fi

case $COMMAND in
  start)
    docker run --rm --name test -p8080:8080 mapway/geoserver:4.1 
    ;;
  stop)
    docker stop test
    ;;
  *)
    usage
    ;;
esac
