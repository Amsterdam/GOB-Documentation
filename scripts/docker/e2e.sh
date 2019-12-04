#!/bin/bash

set -u
source bash.color.env

API_BASE="http://localhost:8141/gob"

info() {
  echo "${YELLOW}${1}${NC}"
}

start_workflow() {
  docker exec gobworkflow python -m gobworkflow.start $1 > /dev/null
}

step () {
  start_workflow "${1}"
  sleep 15
}

compare_files() {
  sort -o output.$1.ndjson output.$1.ndjson
  DIFF=$(diff output.$1.ndjson expect.$1.ndjson)

  if [ $? -ne 0 ]; then
    echo "${RED}FAILED${NC}"
  else
    echo "${GREEN}OK${NC}"
  fi
}

check () {
  curl -s "${API_BASE}/test_catalogue/test_entity/?ndjson=true" -o output.$1.ndjson
  compare_files $1
}

check_relation() {
  echo -n "Check relation ${1} "
  curl -s "${API_BASE}/dump/rel/${1}/?format=csv" -o output.$1.ndjson
  compare_files $1
}

check_relations() {
  # Check all relations from source entities RTA and RTB to destination entities RTC and RTD
  for SRC_ENTITY in rta rtb
  do
    for DST_REL in rtc_ref_to_c rtc_manyref_to_c rtd_ref_to_d rtd_manyref_to_d
    do
      check_relation "tst_${SRC_ENTITY}_tst_${DST_REL}"
    done
  done
}

info "Test imports"
for IMPORT in DELETE_ALL ADD MODIFY1 DELETE_ALL ADD MODIFY1
do
  echo -n "Test ${IMPORT} "
  step "import test_catalogue test_entity ${IMPORT}"
  check "${IMPORT}"
done

info "Test relations"

info "Import relation entities"

for ENTITY in rel_test_entity_a rel_test_entity_b rel_test_entity_c rel_test_entity_d
do
  start_workflow "import test_catalogue ${ENTITY} REL"
done
sleep 15

info "Run relate"
start_workflow "relate test_catalogue"
sleep 15

check_relations

