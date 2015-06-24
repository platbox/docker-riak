#! /bin/bash

set -e

source $(dirname $0)/docker.host.sh

RANDOM_CONTAINER_ID=$(docker ps | egrep "platbox/riak" | cut -d" " -f1 | perl -MList::Util=shuffle -e'print shuffle<>' | head -n1)
CONTAINER_HTTP_PORT=$(docker port "${RANDOM_CONTAINER_ID}" 8098 | cut -d ":" -f2)

curl -s "http://${CLEAN_DOCKER_HOST}:${CONTAINER_HTTP_PORT}/stats" | python -mjson.tool

