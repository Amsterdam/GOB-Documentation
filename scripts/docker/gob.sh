#!/bin/bash


# Bash env files directory (GOB-Documentation/scripts/)
ENV_DIR="$( dirname $0 )/.."
source "$ENV_DIR/bash.color.env"
source "$ENV_DIR/bash.out.env"

# Change to GOB directory
cd "$( dirname $0 )/../../.."
GOB_BASE_DIR="${PWD}"

# Script usage.
USAGE="Usage: $( basename $0 ) (--force) [start|stop|ls|version]"

# GOB components (compose projects).
ALL_REPOS="Workflow Import Prepare Upload API Export Test Message StUF Management Management-Frontend Distribute BagExtract EventConsumer EventProducer"

REPOS=${REPOS:-${ALL_REPOS}}

# GOB Infrastructure compose project.
INFRA="Infra"

stop_project () {
    cd "${GOB_BASE_DIR}/${1}"
    docker compose ps --services --status=running |
    while read service
    do
        if [ -n "${service}" ]; then
            echo "  ${service}"
        fi
    done
    docker compose down >/dev/null 2>&1
    cd - >/dev/null
}

stop_projects () {
    # Stop any running GOB compose project
    for REPO in ${REPOS} ${INFRA}
    do
        echo "Stopping ${BOLD_BLACK}GOB ${REPO}${NC}"
        stop_project "GOB-${REPO}"
    done
}

list_services () {
    cd "${GOB_BASE_DIR}/${1}"
    RUNNING=$(docker compose ps --services --status=running)
    docker compose config --services |
    while read service
    do
        GREP=$(echo "${RUNNING}" | grep "^${service}$") || true
        if [ -n "${GREP}" ]; then
            echo "  ${service} ${GREEN}UP${NC}"
        else
            echo "  ${service} ${RED}DOWN${NC}"
        fi
    done
    cd - >/dev/null
}

show_projects () {
    for REPO in ${INFRA} ${REPOS}
    do
        echo "${BOLD_BLACK}GOB ${REPO}${NC}:"
        list_services "GOB-${REPO}"
    done
}

start_infra () {
    SERVICE=$1
    WAIT_FOR=$2
    TEMPFILE=$(mktemp start_infra.XXXXXX)
    echo -n "Starting ${SERVICE}"
    (docker compose up $1 | tee $TEMPFILE) >> ${OUT} 2>&1 &
    until grep "$WAIT_FOR" $TEMPFILE; do
        echo -n "."
        sleep 1
    done
    rm -rf $TEMPFILE
}

init () {
    echo -e "\nCreating network gob-network"
    docker network create gob-network

    echo "Creating volume gob-volume"
    GOB_VOLUME_DIR=${HOME}/gob-volume
    mkdir -m 777 -p $GOB_VOLUME_DIR/message_broker
    docker volume create gob-volume --opt device=$GOB_VOLUME_DIR --opt o=bind --opt type=tmpfs > /dev/null

    echo "Init .env for relevant compose projects"
    for REPO_DIR in $(find . -name ".env.example" -maxdepth 2 -type f | xargs dirname)
    do
        cd $REPO_DIR
        if [ ! -f .env ]
        then
            echo "Create empty credentials file (.env) for `basename ${REPO_DIR}`"
            cp .env.example .env
        fi
        cd - > /dev/null
    done
}

get_gob_version () {
    # Return current version of GOB-Core or GOB-Config
    cd "GOB-$1"
    local CURRENT_VERSION=$(git describe --abbrev=0 --tags)
    cd ..
    echo "${CURRENT_VERSION}"
}

show_component_version () {
    # $1: Core|Config; $2: ${CURRENT_CORE_VERSION}|${CURRENT_CONFIG_VERSION}

    # GOB-(Core|Config) version of GOB component
    if [ -f src/requirements.txt ]; then
        local COMP_VERSION=$(grep "GOB-$1" src/requirements.txt | sed -E "s/^.*@(v[0-9.]+).*$/\1/")
        if [ -n "${COMP_VERSION}" ]; then
            echo -n "$1 version"
            if [ "${COMP_VERSION}" = "$2" ]; then
                echo -n "${GREEN}"
            else
                echo -n "${RED}"
            fi
            echo " ${COMP_VERSION} ${NC}"
        fi
    fi
}

start () {
    # Save docker output in $OUT
    if [ -f "${OUT}" ]; then
        rm ${OUT}
    fi

    # Initialize GOB, ignore errors
    init 2> /dev/null || true
    echo -e "${BOLD_BLACK}Output${NC} in ${OUT}\n"

    # Start GOB Infrastructure first
    cd "GOB-${INFRA}"
    echo "Starting ${BOLD_BLACK}GOB Infrastructure${NC}"
    for SERVICE in database management_database; do
        start_infra $SERVICE "database system is ready to accept connections"
    done
    start_infra rabbitmq "Server startup complete"
    cd ..

    # GOB Core version
    CURRENT_CORE_VERSION=$(get_gob_version "Core")
    echo "${BOLD_BLACK}GOB Core${NC} Version: ${GREEN}${CURRENT_CORE_VERSION}${NC}"

    # GOB Config version
    CURRENT_CONFIG_VERSION=$(get_gob_version "Config")
    echo "${BOLD_BLACK}GOB Config${NC} Version: ${GREEN}${CURRENT_CONFIG_VERSION}${NC}"

    # GOB components.
    export GOBOPTIONS=
    for REPO in ${REPOS}
    do
        GOB_REPO="GOB-${REPO}"

        # Initialize each repository
        cd ${GOB_REPO}
        echo "Starting ${BOLD_BLACK}GOB ${REPO}${NC}"

        # GOB Core version
        show_component_version "Core" "${CURRENT_CORE_VERSION}"
        # GOB Config version
        show_component_version "Config" "${CURRENT_CONFIG_VERSION}"

        echo "Building ${GOB_REPO} compose project"
        docker compose build > /dev/null
        echo "Starting ${GOB_REPO} compose project"
        docker compose up >> ${OUT} 2>&1 &

        cd ..
    done
}

show_versions () {
    # Current GOB Core version
    CURRENT_CORE_VERSION=$(get_gob_version "Core")
    echo "${BOLD_BLACK}GOB Core${NC} Version: ${GREEN}${CURRENT_CORE_VERSION}${NC}"
    # Current GOB Config version
    CURRENT_CONFIG_VERSION=$(get_gob_version "Config")
    echo -e "${BOLD_BLACK}GOB Config${NC} Version: ${GREEN}${CURRENT_CONFIG_VERSION}${NC}\n"

    # Show Core and Config versions of GOB component
    for REPO in ${REPOS}
    do
        cd "GOB-${REPO}"

        echo "${BOLD_BLACK}GOB ${REPO}${NC}"

        # GOB Core version
        show_component_version "Core" "${CURRENT_CORE_VERSION}"
        # GOB Config version
        show_component_version "Config" "${CURRENT_CONFIG_VERSION}"

        cd ..
    done
}


if [ -z "$1" ]
then
  echo -e "Parameters missing.\n${USAGE}"
  exit 1
fi

if [ "$1" == "--force" ]
then
    shift
else
    set -u # crash on missing env
    set -e # stop on any error
fi

if [ "$1" == "start" ]; then
    stop_projects
    start
    sleep 10
    echo
    show_projects
elif [ "$1" == "ls" ]; then
    show_projects
elif [ "$1" == "stop" ]; then
    stop_projects
elif [ "$1" == "version" ]; then
    show_versions
else
  echo -e "Invalid parameter '$1'.\n${USAGE}"
  exit 1
fi
