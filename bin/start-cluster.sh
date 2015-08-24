#! /bin/bash

set -e

source $(dirname $0)/docker.host.sh

DOCKER_RIAK_CLUSTER_SIZE=${DOCKER_RIAK_CLUSTER_SIZE:-5}

if docker ps -a | grep "${DOCKER_IMAGE}" >/dev/null; then
  echo ""
  echo "It looks like you already have some Riak containers running."
  echo "Please take them down before attempting to bring up another"
  echo "cluster."
  echo ""

  exit 1
fi

echo
echo "Bringing up cluster nodes:"
echo

# The default allows Docker to forward arbitrary ports on the VM for the Riak
# containers. Ports used by default are usually in the 49xx range.

publish_http_port="8098"
publish_pb_port="8087"

# If DOCKER_RIAK_BASE_HTTP_PORT is set, port number
# $DOCKER_RIAK_BASE_HTTP_PORT + $index * 2 gets forwarded to 8098 and
# $DOCKER_RIAK_BASE_HTTP_PORT + $index * 2 + 1 gets forwarded to 8087.

DOCKER_RIAK_PROTO_BUF_PORT_OFFSET=${DOCKER_RIAK_PROTO_BUF_PORT_OFFSET:-100}
DOCKER_BASE_ARGS=$(echo \
  "-d" \
  "-e" "DOCKER_RIAK_CLUSTER_SIZE=${DOCKER_RIAK_CLUSTER_SIZE}" \
  "-e" "DOCKER_RIAK_AUTOMATIC_CLUSTERING=${DOCKER_RIAK_AUTOMATIC_CLUSTERING}"
)

for index in $(seq -f "%02g" "1" "${DOCKER_RIAK_CLUSTER_SIZE}");
do

  if [[ ! -z $DOCKER_RIAK_BASE_HTTP_PORT ]] ; then
    final_http_port=$((DOCKER_RIAK_BASE_HTTP_PORT + (index - 1) * 2))
    final_pb_port=$((DOCKER_RIAK_BASE_HTTP_PORT + (index - 1) * 2 + 1))
    publish_http_port="${final_http_port}:8098"
    publish_pb_port="${final_pb_port}:8087"
  fi

  DOCKER_ARGS=$(echo \
    "${DOCKER_BASE_ARGS}" \
    "-p" $publish_http_port \
    "-p" $publish_pb_port \
    "-v" /var/lib/riak${index}:/var/lib/riak \
    --name "riak${index}"
  )

  if [ "${index}" -gt "1" ] ; then
    docker run ${DOCKER_ARGS} --link "riak01:seed" ${DOCKER_IMAGE}
  else
    docker run ${DOCKER_ARGS} ${DOCKER_IMAGE}
  fi

  CONTAINER_ID=$(docker ps | egrep "riak${index}[^/]" | cut -d" " -f1)
  CONTAINER_PORT=$(docker port "${CONTAINER_ID}" 8098 | cut -d ":" -f2)

  until curl -s "http://${CLEAN_DOCKER_HOST}:${CONTAINER_PORT}/ping" | grep "OK" > /dev/null 2>&1;
  do
    sleep 2
  done

  echo "  Successfully brought up [riak${index}]"
done

echo
echo "Please wait approximately 30 seconds for the cluster to stabilize."
echo
