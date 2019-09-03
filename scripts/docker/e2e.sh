#!/bin/bash

set -u
source bash.color.env

step () {
  docker exec gobworkflow python -m gobworkflow.start $1 > /dev/null
  sleep 15
}

check () {
  curl -s "http://localhost:8141/gob/test_catalogue/test_entity/?ndjson=true" -o output.$1.ndjson
  sort -o output.$1.ndjson output.$1.ndjson
  DIFF=$(diff output.$1.ndjson expect.$1.ndjson)
  if [ "$DIFF" != "" ]; then
    echo "${RED}FAILED${NC}"
  else
    echo "${GREEN}OK${NC}"
  fi
}

# start the imports
for IMPORT in DELETE_ALL ADD MODIFY1 DELETE_ALL ADD MODIFY1
do
  echo -n "Test ${IMPORT} "
  step "import test_catalogue test_entity ${IMPORT}"
  check "${IMPORT}"
done
