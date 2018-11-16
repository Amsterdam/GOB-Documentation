#!/usr/bin/env bash

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# List of all GOB repositories.
BASE_REPOS="Infra Core"
REPOS="Workflow Import Upload API Export Management Management-Frontend"

# Color constants
NC=$'\e[0m'
RED=$'\e[31m'
GREEN=$'\e[32m'

# Change to GOB directory
cd $SCRIPTDIR/../..

for REPO in ${BASE_REPOS} ${REPOS}
do
    GOB_REPO="GOB-${REPO}"

    # Check if all repositories exist
    if [ -d ${GOB_REPO} ]; then
        echo ${GREEN} ${GOB_REPO} ${NC}
    else
        # Clone any missing repository
        echo ${RED} ${GOB_REPO} is missing, cloning...
        git clone git@github.com:Amsterdam/${GOB_REPO}.git ${NC}
    fi

    # Initialize each repository
    cd ${GOB_REPO}

        if [ "$REPO" = "Management-Frontend" ]; then
            echo Running npm install
            npm install > /dev/null
        elif [ "$REPO" = "Infra" ]; then
            echo Starting GOB infrastructure
            # Stop any existing GOB infrastructure dockers
            docker stop rabbitmq storage management_database > /dev/null 2>&1
            # (Re-)start
            docker-compose up > /dev/null 2>&1 &
            sleep 1
        else
            if [ ! -d venv ]; then
                echo Create virtual environment
                python3 -m venv venv
            fi
            source venv/bin/activate

            if [ "$REPO" != "Core" ]; then
                cd src
            fi

                echo Install requirements
                pip install -r requirements.txt > /dev/null

                echo Run tests
                sh test.sh > /dev/null

            if [ "$REPO" != "Core" ]; then
                cd ..
            fi

            deactivate
        fi

    cd ..
done

echo Basic setup completed
echo Starting GOB...

PIDS=""
for REPO in $REPOS
do
    GOB_REPO="GOB-${REPO}"

    echo -n "${GREEN} Starting ${GOB_REPO}"

    # "Spin up" each repository
    cd ${GOB_REPO}

        if [ "$REPO" = "Management-Frontend" ]; then
            (npm run serve > /dev/null 2>&1) &
            sleep 2
            PID="$(pidof node)"
        else
            source venv/bin/activate
            cd src
                PACKAGE=$(echo gob${REPO} | tr '[:upper:]' '[:lower:]')
                python -m ${PACKAGE} > /dev/null  2>&1 &
                PID="$!"
            cd ..
            deactivate
        fi

        echo " OK, PID ${PID} ${NC}"
        PIDS="${PIDS} ${PID}"
        sleep 1

    cd ..

done

echo GOB is active, PIDS: ${PIDS}
