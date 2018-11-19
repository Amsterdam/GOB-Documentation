#!/usr/bin/env bash

# Color constants
NC=$'\e[0m'
RED=$'\e[31m'
GREEN=$'\e[32m'

# Required software and versions
REQUIREMENTS="docker docker_compose python3 node npm"
export REQUIRED_VERSION_docker=18.03
export REQUIRED_VERSION_docker_compose=1.17
export REQUIRED_VERSION_python3=3.6
export REQUIRED_VERSION_node=8.11
export REQUIRED_VERSION_npm=6.4

NERRORS=0
for REQUIREMENT in ${REQUIREMENTS}; do
    # Show package
    PACKAGE=$(echo ${REQUIREMENT} | tr "_" "-")
    echo -n "${PACKAGE} "

    # Test if package is installed
    if [ "$(which ${PACKAGE})" = "" ]; then
        echo "${RED}not installed.${NC}"
            NERRORS=$(expr ${NERRORS} + 1)
    else
        # Test if package matches minimal version
        PACKAGE_VERSION=$(${PACKAGE} --version | sed -E "s/^[^[:digit:]]*([[:digit:]]+\.[[:digit:]]+).*$/\1/")
        REQUIRED_VERSION=$(sh -c "echo \${REQUIRED_VERSION_${REQUIREMENT}}")

        # Determine lowest of package version and required version
        LOWEST_VERSION=$(printf '%s\n' "${REQUIRED_VERSION}" "${PACKAGE_VERSION}" | sort -V | head -n1)

        # If the lowest version is the required version then version is OK
        if [ "${LOWEST_VERSION}" = "${REQUIRED_VERSION}" ]; then
            echo "${GREEN}${PACKAGE_VERSION} >= ${REQUIRED_VERSION}${NC}"
        else
            echo "${RED}${PACKAGE_VERSION} < ${REQUIRED_VERSION}${NC}"
            NERRORS=$(expr ${NERRORS} + 1)
        fi
    fi
done

exit ${NERRORS}
