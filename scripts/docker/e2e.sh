#!/bin/bash

set -e # stop on any error
source bash.env

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$( cd "$( dirname "$0" )" >/dev/null && pwd )"

# List of all tests
TEST_SIMPLE="DELETE_ALL ADD ADD DELETE_ALL ADD MODIFY DELETE DELETE_ALL EMPTY DELETE_ALL"
TEST_TYPES=""

# Temp turned off tests, until Invalid Geotypes are rejected by GOB-Import
# NON_GEOMETRY NON_POLYGON
for TEST in NON_INTEGER NON_DECIMAL NON_CHARACTER NON_DATE NON_BOOLEAN NON_JSON NON_DATETIME NON_POINT NON_REFERENCE; do
    TEST_TYPES="${TEST_TYPES} DELETE_ALL ${TEST}"
done

# Concatenate tests
if [ -z "$1" ]; then
    TESTS="${TEST_SIMPLE} ${TEST_TYPES}"
else
    TESTS="$@"
fi
TESTS_DIR=data/test

echo Starting tests
N_ERRORS=0
ERRORS=""

API="http://localhost:8141/gob/test_catalogue/test_entity/"

get_completed(){
    expr $(grep -e "\(UPDATE]\s\+Update completed\|Import has failed\)" ${OUT}  | wc -l) + 1
}

for TEST in ${TESTS}; do
    stime=$SECONDS
    completed=$( get_completed || expr 0)
    echo Start import for test ${TEST}
    docker exec gobimport sh data/test/run_test.sh ${TEST}
    docker exec gobworkflow python -m gobworkflow.start import data/test/test.json
    # test is read from test.csv, copy test-csv to test.csv
    # Take some time to let GOB read the file
    echo Get API output for test ${TEST}
    EXPECT=${SCRIPTDIR}/${TEST}.expect
    if [ ! -f ${EXPECT} ]; then
        EXPECT="${SCRIPTDIR}/DELETE_ALL.expect"
    fi
    while [[ $(get_completed) != $(expr ${completed} + 1) ]]; do
        echo "Waiting for update complete..."
        sleep 0.5
    done
    echo "Verifying update via API"
    ERROR=$(cat $EXPECT | python3 client.py $API)

    # Uncomment next two line to redefine expectations
    # echo "${RED}Taking current output as expected output.${NC}"
    # echo ${OUTPUT} > ${EXPECT}
    time_verb="(finished in $(($SECONDS - $stime)) seconds)"
    if [ -z "$ERROR" ]; then
        echo "${GREEN}${TEST} OK ${NC} ${time_verb}"
    else
        echo "${RED}${TEST} FAILED ${NC} ${time_verb}, output:"
        echo "${ERROR}"
        N_ERRORS=$(expr ${N_ERRORS} + 1)
        ERRORS="${ERRORS} ${TEST}"
    fi
done

echo "Test done, ${N_ERRORS} errors${RED}${ERRORS}${NC}"
exit ${N_ERRORS}
