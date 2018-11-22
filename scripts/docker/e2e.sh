#!/usr/bin/env bash

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# List of all tests
TEST_SIMPLE="DELETE_ALL ADD ADD DELETE_ALL ADD MODIFY DELETE DELETE_ALL"
TEST_TYPES=""
for TEST in NON_INTEGER NON_DECIMAL NON_CHARACTER NON_DATE NON_GEOMETRY NON_BOOLEAN; do
    TEST_TYPES="${TEST_TYPES} DELETE_ALL ${TEST}"
done

# Concatenate tests
if [ -z "$1" ]; then
    TESTS="${TEST_SIMPLE} ${TEST_TYPES}"
else
    TESTS="$@"
fi
TESTS_DIR=data/test

# Allow some time for processing the imports and exports
SLEEP=8

# Color constants
NC=$'\e[0m'
RED=$'\e[31m'
GREEN=$'\e[32m'

# Change to GOB directory
cd $SCRIPTDIR/../..

echo Starting tests
N_ERRORS=0
ERRORS=""

API="http://localhost:8141/gob/test_catalogue/test_entity/"
for TEST in ${TESTS}; do

    cd GOB-Import
        echo Start import for test ${TEST}
        docker exec gobimport sh data/test/run_test.sh ${TEST}
        # test is read from test.csv, copy test-csv to test.csv
        # Take some time to let GOB read the file
        sleep ${SLEEP}
        echo Start export for test ${TEST}
        OUTPUT=/tmp/${TEST}.out
        EXPECT=${SCRIPTDIR}/${TEST}.expect
        if [ ! -f ${EXPECT} ]; then
            EXPECT="${SCRIPTDIR}/DELETE_ALL.expect"
        fi
        curl ${API} | python -m json.tool > ${OUTPUT}
        # Uncomment next two line to redefine expectations
        # echo "${RED}Taking current output as expected output.${NC}"
        # cp ${OUTPUT} ${EXPECT}
        echo ======== Result ========
        cat ${OUTPUT}
        echo ========================
        if [ "$(jq -S . ${OUTPUT})" = "$(jq -S .  ${EXPECT})" ]; then
            echo "${GREEN}${TEST} OK ${NC}"
        else
            echo "${RED}${TEST} FAILED ${NC}, expected:"
            cat ${EXPECT}
            N_ERRORS=$(expr ${N_ERRORS} + 1)
            ERRORS="${ERRORS} ${TEST}"
        fi
        rm ${OUTPUT}
    cd ..

done

echo "Test done, ${N_ERRORS} errors${RED}${ERRORS}${NC}"
exit ${N_ERRORS}
