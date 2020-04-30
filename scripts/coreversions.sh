#!/bin/bash

source bash.color.env
source bash.out.env

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$( cd "$( dirname "$0" )" >/dev/null && pwd )"
cd $SCRIPTDIR/../..

REPOS="Workflow Import Prepare Upload API Export Test Management"
LIBS="Core Config"

# Use date in to create a new branch for any required update
DT=$(date +"%Y%m%d_%H%M")
UPDATE_BRANCH="update_shared_${DT}"

# The file to update
LOCAL_REQUIREMENTS=src/requirements.txt

get_lib_version () {
  cd ${GOB_LIB}
  LIB_VERSION=$(git describe --tags `git rev-list --tags --max-count=1`)
  cd ..
}

get_repo_lib_version () {
  REQUIREMENTS="${GOB_REPO}/${LOCAL_REQUIREMENTS}"
  SED_EXPR="^(.*${GOB_LIB}.git@)(v.*)(#.*)$"
  REPO_LIB_VERSION=$(grep ${GOB_LIB} ${REQUIREMENTS} | sed -E "s/${SED_EXPR}/\2/")
}

show_version () {
  if [ ! -z ${REPO_LIB_VERSION} ]; then
    # If a repo version for the specific lib exists then show the version
    # If the version matches the latest version then the message is printed in green
    # If the version doesn't match the latest version then the message is printed in red
    # and also show the latest version
    BASE_MSG="${GOB_REPO} ${GOB_LIB} ${REPO_LIB_VERSION}"
    if [ "${REPO_LIB_VERSION}" = "${LIB_VERSION}" ]; then
      # Version is up-to-date
      VERSION_OUTDATED=0
      MSG="${GREEN}${BASE_MSG}"
    else
      # Version is not the latest version
      VERSION_OUTDATED=1
      MSG="${RED}${BASE_MSG} != ${LIB_VERSION}"
    fi
    echo "${MSG}${NC}"
  fi
}

update_version () {
  # Update the version for the specific lib to the latest version
  echo Update ${REPO_LIB_VERSION} "${LIB_VERSION}"
  if [ ! -z ${REPO_LIB_VERSION} ] && [ "${REPO_LIB_VERSION}" != "${LIB_VERSION}" ]; then
    # The repo has a lib version that is not equal to the latest version
    TMP_REQUIREMENTS=${REQUIREMENTS}.$$$
    cat ${REQUIREMENTS} | sed -E "s/${SED_EXPR}/\1${LIB_VERSION}\3/" > ${TMP_REQUIREMENTS}
    mv ${TMP_REQUIREMENTS} ${REQUIREMENTS}
  fi
}

get_current_branch () {
  cd $GOB_REPO
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  cd ..
}

set_develop_branch () {
  get_current_branch

  if [ ${CURRENT_BRANCH} != "develop" ]; then
    cd $GOB_REPO
    echo "${GOB_REPO}: set branch to develop"
    git checkout develop > /dev/null
    git pull > /dev/null
    cd ..
  fi
}

set_update_branch () {
  get_current_branch

  # Create a branch for the lib update
  if [ ${CURRENT_BRANCH} != ${UPDATE_BRANCH} ]; then
    cd $GOB_REPO
    # Update branch doesn't yet exist
    git checkout -b "update_shared_${DT}"
    cd ..
  fi
}

commit_update () {
  cd $GOB_REPO
  git add $LOCAL_REQUIREMENTS
  git commit -m "Update ${GOB_LIB} version from ${REPO_LIB_VERSION} to ${LIB_VERSION}"\
             -m ""\
             -m "Automated update of ${GOB_LIB} to its latest version"
  cd ..
}

usage () {
  echo "Usage: $(basename $0) [--update]"
  echo "Show versions of shared libraries for each GOB repository"
  echo ""
  echo "  --update           Update the version to the latest version in a new branch"
  echo "  --back-to-develop  Set every repo back to the development branch"
  echo ""
  exit 1
}

# The script works on the basis of an up-to-date development branch
# The first step is to set every repo to the develop branch
for REPO in ${REPOS}; do
  GOB_REPO="GOB-${REPO}"
  set_develop_branch
done

# Parse command line arguments
UPDATE_VERSIONS=0
if [ "$1" = "--update" ]; then
  # Show versions and update when there are conflicts
  UPDATE_VERSIONS=1
elif [ "$1" = "--back-to-develop" ]; then
  # Already done during startup
  exit 0
elif [ ! -z "$1" ]; then
  # Unknown parameter, show usage
  usage
fi

for REPO in ${REPOS}; do
  GOB_REPO="GOB-${REPO}"

  for LIB in ${LIBS}; do
    GOB_LIB="GOB-${LIB}"
    get_lib_version
    get_repo_lib_version
    show_version

    if [ ${VERSION_OUTDATED} = 1 ] && [ ${UPDATE_VERSIONS} = 1 ]; then
      set_update_branch
      update_version
      commit_update
    fi
  done
done
