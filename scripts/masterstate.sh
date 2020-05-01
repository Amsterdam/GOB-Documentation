#!/bin/bash

source bash.color.env
source bash.out.env

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$(cd "$(dirname "$0")" >/dev/null && pwd)"
cd $SCRIPTDIR/../..

REPOS="Workflow Import Prepare Upload API Export Test Management Management-Frontend StUF"

usage() {
  echo "Usage: bash $(basename $0)"
  echo "Show any out of date master repositories"
  echo ""
  exit 1
}

if [ ! -z "$1" ]; then
  usage
fi

for REPO in ${REPOS}; do
  GOB_REPO="GOB-${REPO}"
  cd $GOB_REPO
  echo -n "${GOB_REPO} "

  # Update remote repositories
  git fetch

  # Get diffs between develop and master
  DIFFS=$(git diff --name-status origin/develop origin/master)
  if [ ! -z "${DIFFS}" ]; then
    echo "${RED}Out of date${NC}"
  else
    echo "${GREEN}OK${NC}"
  fi

  # Show any non develop, master or demo branch
  BRANCHES=$(git ls-remote --heads -q | grep -v -E "develop|master|demo" | awk '{gsub("refs/heads/","",$2); print $2}')
  if [ ! -z "$BRANCHES" ]; then
    for BRANCH in $BRANCHES; do
      echo "  $BRANCH"
    done
  fi

  cd ..
done
