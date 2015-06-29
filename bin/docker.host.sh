#! /bin/bash

DOCKER_IMAGE="platbox/riak"

if [ -z "${DOCKER_HOST}" ]; then
  echo ""
  echo "It looks like the environment variable DOCKER_HOST has not"
  echo "been set.  The Riak cluster cannot be started unless this has"
  echo "been set appropriately.  For example:"
  echo ""
  echo "  export DOCKER_HOST=\"tcp://127.0.0.1:2375\""
  echo ""
  exit 1
fi

if [[ "${DOCKER_HOST}" == unix://* ]]; then
  CLEAN_DOCKER_HOST="localhost"
else
  CLEAN_DOCKER_HOST=$(echo "${DOCKER_HOST}" | cut -d'/' -f3 | cut -d':' -f1)
fi

