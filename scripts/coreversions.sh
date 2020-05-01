#!/bin/bash

source bash.color.env
source bash.out.env

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$(cd "$(dirname "$0")" >/dev/null && pwd)"
cd $SCRIPTDIR/../..

REPOS="Workflow Import Prepare Upload API Export Test Management"
LIBS="Core Config"

# Use date in to create a new branch for any required update
DT=$(date +"%Y%m%d_%H%M")
UPDATE_BRANCH="update_shared_${DT}"

# The file to update
LOCAL_REQUIREMENTS=src/requirements.txt

update_libs() {
  for LIB in ${LIBS}; do
    GOB_LIB="GOB-${LIB}"
    echo "Update ${GOB_LIB}..."
    cd ${GOB_LIB}
    $EXEC git pull
    cd ..
  done
}

get_lib_version() {
  cd ${GOB_LIB}
  LIB_VERSION=$(git describe --tags $(git rev-list --tags --max-count=1))
  cd ..
}

get_repo_lib_version() {
  REQUIREMENTS="${GOB_REPO}/${LOCAL_REQUIREMENTS}"
  SED_EXPR="^(.*${GOB_LIB}.git@)(v.*)(#.*)$"
  REPO_LIB_VERSION=$(grep ${GOB_LIB} ${REQUIREMENTS} | sed -E "s/${SED_EXPR}/\2/")
}

show_version() {
  if [ ! -z "${REPO_LIB_VERSION}" ]; then
    # If a repo version for the specific lib exists then show the version
    # If the version matches the latest version then the message is printed in green
    # If the version doesn't match the latest version then the message is printed in red
    # and also show the latest version
    BASE_MSG="${GOB_REPO} ($CURRENT_BRANCH) ${GOB_LIB} ${REPO_LIB_VERSION}"
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

init_updates() {
  UPDATE_MSG=""
}

set_update_message() {
  MSG=$1

  echo "Update ${MSG}"
  if [ -z "${UPDATE_MSG}" ]; then
    # First update
    UPDATE_MSG="Update"
  else
    # Multiple updates
    UPDATE_MSG="${UPDATE_MSG},"
  fi
  UPDATE_MSG="${UPDATE_MSG} $MSG"
}

update_version() {
  # Update the version for the specific lib to the latest version
  if [ ! -z "${REPO_LIB_VERSION}" ] && [ "${REPO_LIB_VERSION}" != "${LIB_VERSION}" ]; then
    set_update_message "${GOB_LIB} ${REPO_LIB_VERSION} to ${LIB_VERSION}"
    # The repo has a lib version that is not equal to the latest version
    $EXEC sed -i -E "s/${SED_EXPR}/\1${LIB_VERSION}\3/" ${REQUIREMENTS}
  fi
}

get_current_branch() {
  cd $GOB_REPO
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  cd ..
}

set_all_to_develop() {
  for REPO in ${REPOS}; do
    GOB_REPO="GOB-${REPO}"
    set_develop_branch
  done
}

set_develop_branch() {
  get_current_branch

  if [ "${CURRENT_BRANCH}" != "develop" ]; then
    cd $GOB_REPO
    echo "${GOB_REPO}: set branch to develop"
    $EXEC git checkout develop
    $EXEC git pull
    cd ..
  fi
}

set_update_branch() {
  # Create a branch for the lib update
  # Only create branch when on develop, else commit in current branch
  if [ "${CURRENT_BRANCH}" = "develop" ]; then
    cd $GOB_REPO
    $EXEC git checkout -b "update_shared_${DT}"
    cd ..
  fi
}

commit_any_updates() {
  if [ ! -z "$UPDATE_MSG" ]; then
    cd $GOB_REPO
    $EXEC git add $LOCAL_REQUIREMENTS
    $EXEC git commit \
      -m "$UPDATE_MSG" \
      -m "" \
      -m "Automated update of shared lib(s) to their latest version"
    cd ..
  fi
}

usage() {
  echo "Usage: $(basename $0) [--dry-run] [--update | --back-to-develop]"
  echo "Show versions of shared libraries for each GOB repository"
  echo ""
  echo "  --dry-run          Show actions that would be executed"
  echo "  --update           Update the version to the latest version in a new branch"
  echo "  --back-to-develop  Set every repo back to the development branch"
  echo ""
  exit 1
}

# Parse command line arguments
EXEC=""
if [ "$1" = "--dry-run" ]; then
  EXEC="echo"
  shift
fi

UPDATE_VERSIONS=0
if [ "$1" = "--update" ]; then
  # Show versions and update when any shared lib is out-of-date
  UPDATE_VERSIONS=1
elif [ "$1" = "--back-to-develop" ]; then
  set_all_to_develop
  exit 0
elif [ ! -z "$1" ]; then
  # Unknown parameter, show usage
  usage
fi

update_libs

for REPO in ${REPOS}; do
  GOB_REPO="GOB-${REPO}"
  get_current_branch
  init_updates

  for LIB in ${LIBS}; do
    GOB_LIB="GOB-${LIB}"
    get_lib_version
    get_repo_lib_version
    show_version

    if [ ${VERSION_OUTDATED} = 1 ] && [ ${UPDATE_VERSIONS} = 1 ]; then
      set_update_branch
      update_version
    fi
  done

  commit_any_updates
done
