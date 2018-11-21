#!/usr/bin/env bash

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# List of all GOB repositories.
BASE_REPOS="Infra Core"
REPOS="Workflow Import Upload API Export Management Management-Frontend"

# Git access via HTTPS or SSH
GIT_HTTPS="https://github.com/"
GIT_GIT="git@github.com:"
GIT_ACCESS=${GIT_HTTPS}

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
    if [ ! -d ${GOB_REPO} ]; then
        # Clone any missing repository
        echo "${RED} ${GOB_REPO} is missing, cloning...${NC}"
        git clone ${GIT_ACCESS}Amsterdam/${GOB_REPO}.git
    fi

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

                CORE_VERSION=$(grep "GOB-Core" requirements.txt | sed -E "s/^.*@(v.*)#.*$/\1/")
                if [ "$REPO" = "Core" ]; then
                    CURRENT_CORE_VERSION=$(git describe --abbrev=0 --tags)
                    echo "Version: ${CURRENT_CORE_VERSION}"
                elif [ ! -z "${CORE_VERSION} " ]; then
                    echo -n "Core version"
                    if [ "${CORE_VERSION}" = "${CURRENT_CORE_VERSION}" ]; then
                        echo -n "${GREEN}"
                    else
                        echo -n "${RED}"
                    fi
                    echo " ${CORE_VERSION} ${NC}"
                fi

                echo Install requirements
                pip install -r requirements.txt > /dev/null

                echo -n "Run tests "
                sh test.sh > /dev/null
                if [ $? = 0 ]; then
                    echo "${GREEN}OK${NC}"
                else
                    echo "${RED}FAILED!${NC}"
                fi

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

TMPDIR=$(mktemp -d)

for REPO in $REPOS
do
    GOB_REPO="GOB-${REPO}"

    echo -n "${GREEN}Starting ${GOB_REPO}"

    OUT="${TMPDIR}/GOB_${REPO}.out.txt"

    # "Spin up" each repository
    cd ${GOB_REPO}

        if [ "$REPO" = "Management-Frontend" ]; then
            (npm run serve > ${OUT} 2>&1) &
            sleep 2
            PID="$(pidof node)"
        else
            source venv/bin/activate
            if [ -f .env ]; then
                export $(cat .env | xargs)
            fi
            cd src
                PACKAGE=$(echo gob${REPO} | tr '[:upper:]' '[:lower:]')
                python -m ${PACKAGE} > ${OUT}  2>&1 &
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
echo Output can be found in ${TMPDIR}