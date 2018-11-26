#!/bin/bash

set -u # crash on missing env
set -e # stop on any error

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$( cd "$( dirname "$0" )" >/dev/null && pwd )"

# List of all GOB repositories.
BASE_REPOS="Infra Core"
REPOS="Workflow Import Upload API Export Management Management-Frontend"

# GOB Infrastructure dockers
INFRA="rabbitmq storage management_database"

# Color constants
NC=$'\e[0m'
RED=$'\e[31m'
GREEN=$'\e[32m'

# Change to GOB directory
cd $SCRIPTDIR/../../..

stop_docker () {
    DOCKER=$1
    docker stop ${DOCKER}
    # docker rm ${DOCKER}
}

start_infra () {
    SERVICE=$1
    WAIT_FOR=$2
    TEMPFILE=$(mktemp /tmp/start_infra.XXXXXX)
    echo -n "Starting ${SERVICE}"
    (docker-compose up $1 | tee $TEMPFILE) >> ${OUT} 2>&1 &
    until grep "$WAIT_FOR" $TEMPFILE; do
        echo -n "."
        sleep 1
    done
    rm -rf $TEMPFILE
}

init () {
    # Stop any running GOB dockers
    for REPO in ${REPOS}
    do
        echo "Stopping docker GOB ${REPO}"
        DOCKER=$(echo "gob${REPO}" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
        stop_docker $DOCKER > /dev/null
    done

    for DOCKER in ${INFRA}
    do
        echo "Stopping docker GOB ${DOCKER}"
        stop_docker $DOCKER > /dev/null
    done

    echo "Creating network gob-network"
    docker network create gob-network

    echo "Creating volume gob-volume"
    docker volume create gob-volume --opt device=/tmp --opt o=bind > /dev/null
}

start () {
    for REPO in ${BASE_REPOS} ${REPOS}
    do
        echo "${GREEN}${REPO}${NC}"

        GOB_REPO="GOB-${REPO}"

        # Initialize each repository
        cd ${GOB_REPO}

            if [ "$REPO" = "Infra" ]; then
                echo "Starting GOB infrastructure"
                for SERVICE in database management_database; do
                    start_infra $SERVICE "database system is ready to accept connections"
                done
                start_infra rabbitmq "Server startup complete"
            elif [ "$REPO" = "Core" ]; then
                CORE_VERSION=$(grep "GOB-Core" requirements.txt | sed -E "s/^.*@(v.*)#.*$/\1/")
                CURRENT_CORE_VERSION=$(git describe --abbrev=0 --tags)
                echo "GOB Core Version: ${CURRENT_CORE_VERSION}"
            else
                echo "Starting docker GOB ${REPO}"
                CORE_VERSION=$(grep "GOB-Core" src/requirements.txt | sed -E "s/^.*@(v.*)#.*$/\1/")
                echo -n "Core version"
                if [ "${CORE_VERSION}" = "${CURRENT_CORE_VERSION}" ]; then
                    echo -n "${GREEN}"
                else
                    echo -n "${RED}"
                fi
                echo " ${CORE_VERSION} ${NC}"
                echo "Building ${REPO} docker"
                docker-compose build > /dev/null
                echo "Starting ${REPO} docker"
                docker-compose up >> ${OUT} 2>&1 &
            fi

        cd ..
    done
}

# Initialize GOB, ignore errors
init 2> /dev/null || true

# Save docker output in $OUT
OUT=/tmp/gob.out.txt
if [ -f "${OUT}" ]; then
    rm ${OUT}
fi

# build "local" frontend docker
export NPMSCRIPT=builddev

# Start GOB dockers
start

sleep 10
NDOCKERS=$(docker ps --format "{{.Names}}" | grep -e "^gob" | wc -l)
echo "${GREEN}GOB containers (${NDOCKERS}) started, output in ${OUT}${NC}"
