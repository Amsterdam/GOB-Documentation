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
  git remote update origin --prune > /dev/null
  DIFFS=$(git diff --name-status origin/develop origin/master)
  if [ ! -z "${DIFFS}" ]; then
    echo "${RED}Out of date${NC}"
  else
    echo "${GREEN}OK${NC}"
  fi
  cd ..
done
