#!/usr/bin/env bash

# Start from directory where this script is located (GOB-Documentation/scripts)
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

# List of all tests
TESTS="DELETE_ALL ADD ADD DELETE_ALL ADD MODIFY DELETE DELETE_ALL"
TESTS_DIR=data/test

# Allow some time for processing the imports and exports
SLEEP=5

# Color constants
NC=$'\e[0m'
RED=$'\e[31m'
GREEN=$'\e[32m'

# Change to GOB directory
cd $SCRIPTDIR/../..

echo Starting tests
N_ERRORS=0

for TEST in ${TESTS}; do

    cd GOB-Import
        source venv/bin/activate
        cd src
            echo Start import for test ${TEST}
            # test is read from test.csv, copy test-csv to test.csv
            cp ${TESTS_DIR}/test_${TEST}.csv ${TESTS_DIR}/test.csv
            python -m gobimport.start data/test/test.json
            # Take some time to let GOB read the file
            sleep ${SLEEP}
            rm ${TESTS_DIR}/test.csv
        cd ..
        deactivate
    cd ..

    cd GOB-Export
        source venv/bin/activate
        cd src
            echo Start export for test ${TEST}
            OUTPUT=/tmp/${TEST}.out
            EXPECT=${SCRIPTDIR}/${TEST}.expect
            python -m gobexport.start test_catalogue test_entity ${OUTPUT} File
            # Take some time to process the export
            sleep ${SLEEP}
            # Uncomment this line to redefine expectations
            # cp ${OUTPUT} ${EXPECT}
            echo ======== Result ========
            cat ${OUTPUT}
            echo ========================
            if [ "$(cat ${OUTPUT})" = "$(cat ${EXPECT})" ]; then
                echo "${GREEN}OK ${NC}"
            else
                echo "${RED}FAILED ${NC}, expected:"
                cat ${EXPECT}
                N_ERRORS=$(expr ${N_ERRORS} + 1)
            fi
            rm ${OUTPUT}
        cd ..
        deactivate
    cd ..

done

echo "Test done, ${N_ERRORS} errors"
exit ${N_ERRORS}
