#!/usr/bin/env bash

set -u # crash on missing env
set -e # stop on any error

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$( cd "$( dirname "$0" )" >/dev/null && pwd )"

# List of all GOB repositories.
BASE_REPOS="Infra Core"
REPOS="Workflow Import Upload API Export Management Management-Frontend"

# Color constants
NC=$'\e[0m'
RED=$'\e[31m'
GREEN=$'\e[32m'

# Change to GOB directory
cd $SCRIPTDIR/../../..

TMPDIR=$(mktemp -d)
PIDS=""

echo "Stopping any running GOB dockers..."
for REPO in ${REPOS}
do
    DOCKER=$(echo "gob${REPO}" | tr '[:upper:]' '[:lower:]')
    if [ "$REPO" = "Management-Frontend" ]; then
        PSLINES=$(ps -ef | grep -E "node.*vue-cli-service serve" | wc -l)
        if [ $PSLINES -gt 1 ]; then
            kill $(pidof node)
        fi
    else
        docker stop ${DOCKER}
    fi
done
# Stop any existing GOB infrastructure dockers
docker stop rabbitmq storage management_database > /dev/null 2>&1

echo "Starting GOB dockers..."
for REPO in ${BASE_REPOS} ${REPOS}
do
    GOB_REPO="GOB-${REPO}"
    OUT="${TMPDIR}/${GOB_REPO}.out.txt"

    # Initialize each repository
    cd ${GOB_REPO}

        BRANCH=$(git branch | grep \* | cut -d ' ' -f2)
        echo "${GREEN}${GOB_REPO} (${BRANCH})${NC}"
        if [ "${BRANCH}" = "develop" ] || [ "${BRANCH}" = "master" ]; then
            # Auto update develop and master branches
            git pull
        fi
        git fetch

        if [ "$REPO" = "Management-Frontend" ]; then
            echo Running npm install
            npm install > /dev/null
            (npm run serve > ${OUT} 2>&1) &
            sleep 2
            PID="$(pidof node)"
            PIDS="${PIDS} ${PID}"
        elif [ "$REPO" = "Infra" ]; then
            echo Starting GOB infrastructure
            # (Re-)start
            docker-compose up > /dev/null 2>&1 &
            sleep 1
        elif [ "$REPO" = "Core" ]; then
            CORE_VERSION=$(grep "GOB-Core" requirements.txt | sed -E "s/^.*@(v.*)#.*$/\1/")
            CURRENT_CORE_VERSION=$(git describe --abbrev=0 --tags)
            echo "Version: ${CURRENT_CORE_VERSION}"
        else
            CORE_VERSION=$(grep "GOB-Core" src/requirements.txt | sed -E "s/^.*@(v.*)#.*$/\1/")
            echo -n "Core version"
            if [ "${CORE_VERSION}" = "${CURRENT_CORE_VERSION}" ]; then
                echo -n "${GREEN}"
            else
                echo -n "${RED}"
            fi
            echo " ${CORE_VERSION} ${NC}"
            docker-compose -f src/.jenkins/test/docker-compose.yml build > /dev/null
            docker-compose -f src/.jenkins/test/docker-compose.yml run test > /dev/null
            docker-compose build > /dev/null
            docker-compose up &
        fi

    cd ..
done

echo GOB is active, PIDS: ${PIDS}
