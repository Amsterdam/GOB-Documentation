#!/bin/bash

source ../bash.color.env
source ../bash.out.env

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$( cd "$( dirname "$0" )" >/dev/null && pwd )"

# List of all GOB repositories.
BASE_REPOS="Infra Core"
REPOS="Workflow Import Prepare Upload API Export Test Management Management-Frontend"

# GOB Infrastructure dockers
INFRA="rabbitmq storage management_database"

# Change to GOB directory
cd $SCRIPTDIR/../../..

stop_docker () {
    DOCKER=$1
    docker stop ${DOCKER} > /dev/null 2>&1 || true
    # docker rm ${DOCKER}
}

stop_dockers () {
    # Stop any running GOB dockers
    for REPO in ${REPOS}
    do
        echo "Stopping docker GOB ${REPO}"
        DOCKER=$(echo "gob${REPO}" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
        stop_docker $DOCKER > /dev/null
    done

    for DOCKER in ${INFRA} prepare_database
    do
        echo "Stopping docker GOB ${DOCKER}"
        stop_docker $DOCKER > /dev/null
    done
}

show_docker () {
    GREP=$(docker ps | grep $1) || true
    if [ "$GREP" = "" ]; then
        echo " ${RED}DOWN${NC}"
    else
        echo " ${GREEN}UP${NC}"
    fi
}

list_dockers () {
    for REPO in ${REPOS}
    do
        echo -n ${REPO}
        DOCKER=$(echo "gob${REPO}" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
        show_docker ${DOCKER}
    done

    for DOCKER in ${INFRA} prepare_database
    do
        echo -n ${DOCKER}
        show_docker $DOCKER
    done
}

start_infra () {
    SERVICE=$1
    WAIT_FOR=$2
    TEMPFILE=$(mktemp start_infra.XXXXXX)
    echo -n "Starting ${SERVICE}"
    (docker-compose up $1 | tee $TEMPFILE) >> ${OUT} 2>&1 &
    until grep "$WAIT_FOR" $TEMPFILE; do
        echo -n "."
        sleep 1
    done
    rm -rf $TEMPFILE
}

init () {
    echo "Creating network gob-network"
    docker network create gob-network

    echo "Creating volume gob-volume"
    GOB_VOLUME_DIR=${HOME}/gob-volume
    mkdir -m 777 -p $GOB_VOLUME_DIR/message_broker
    docker volume create gob-volume --opt device=$GOB_VOLUME_DIR --opt o=bind --opt type=tmpfs > /dev/null

    echo "Init .env for relevant projects"
    for REPO_DIR in $(find ./ -name ".env.example" -maxdepth 2 -type f | xargs -I{} dirname {})
    do
        cd $REPO_DIR
        if [ ! -f .env ]
        then
            echo "Create empty credentials file (.env) for ${REPO_DIR}"
            cp .env.example .env
        fi
        cd - > /dev/null
    done
}

start () {
    # Save docker output in $OUT
    if [ -f "${OUT}" ]; then
        rm ${OUT}
    fi

    # Initialize GOB, ignore errors
    init 2> /dev/null || true

    # build "local" frontend docker
    export NPMSCRIPT=builddev

    export GOBOPTIONS=
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
                if [ -f src/requirements.txt ]; then
                    CORE_VERSION=$(grep "GOB-Core" src/requirements.txt | sed -E "s/^.*@(v.*)#.*$/\1/")
                    echo -n "Core version"
                    if [ "${CORE_VERSION}" = "${CURRENT_CORE_VERSION}" ]; then
                        echo -n "${GREEN}"
                    else
                        echo -n "${RED}"
                    fi
                    echo " ${CORE_VERSION} ${NC}"
                fi
                echo "Building ${REPO} docker"
                docker-compose build > /dev/null
                echo "Starting ${REPO} docker"
                docker-compose up >> ${OUT} 2>&1 &
            fi

        cd ..
    done
}

if [ "$1" == "--force" ]
then
    shift
else
    set -u # crash on missing env
    set -e # stop on any error
fi

if [ "$1" == "start" ]; then
    stop_dockers
    start
    sleep 10
    list_dockers
    echo "Output in ${OUT}${NC}"
elif [ "$1" == "ls" ]; then
    list_dockers
elif [ "$1" == "stop" ]; then
    stop_dockers
fi
