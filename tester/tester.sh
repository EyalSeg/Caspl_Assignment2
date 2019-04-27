#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ ${1} != '' ]]
then
  ROOT_DIR=${1}
elif [[ `pwd | egrep ".*tester$" > /dev/null; echo $?` == 0 ]]
then
    ROOT_DIR="../"
else
  echo -e "ERROR: Root Dir was not provided.\nUsage: tester.sh <APP_ROOT_DIR_PATH>"
  exit 2
fi

TESTER_DIR="${ROOT_DIR}/tester"
INPUT_DIR="${TESTER_DIR}/input/"
EXPECTED_OUTPUT_DIR="${TESTER_DIR}/expected_output/"
TEST_OUTPUT_DIR="${TESTER_DIR}/test_output/"
INPUT_POSTFIX="_input_"
OUTPUT_POSTFIX="_output_"
EXPECTED_OUTPUT_POSTFIX="_expected_output_"
VALGRING_TEMP="${TEST_OUTPUT_DIR}/valgrind_tmp"

# Assuming app build dir is ${ROOT_DIR}/bin
APP_BUILD_DIR="${ROOT_DIR}/bin/"
APP_EXEC="${APP_BUILD_DIR}/calc"
DEBUG_MODE="${APP_BUILD_DIR}/calc -d"
VALGRIND="valgrind --leak-check=full --show-reachable=yes "

function buildApp() {
  make clean --directory ${ROOT_DIR} --quiet && make --directory ${ROOT_DIR} --quiet

  if [ $? != 0 ]; then
    echo "Build phase failed, exiting.."
    exit 1
  fi
}

function compare() {
  local heaps_blocks_freed="`cat ${VALGRING_TEMP}  | grep -i "All heap blocks were freed -- no leaks are possible" > /dev/null; echo $?`"
  local regex="ERROR SUMMARY: ([0-9]+) errors"
  local errors_summary="`cat ${VALGRING_TEMP}  | egrep -i "${regex}"`"
  [[ $errors_summary =~ $regex ]]
  local total_errors=`echo ${BASH_REMATCH[1]}`

  diff ${EXPECTED_OUTPUT_DIR}${1}${EXPECTED_OUTPUT_POSTFIX}${3} ${2}
  diff_results=$?

  if [[ ${diff_results} != 0 ]]; then
    echo -e "**************${RED} TEST ${4} ${1}_${3} FAILED! difference between expected output above${NC} **************"
  fi
  if [[ ${heaps_blocks_freed} != 0 ]]; then
    echo -e "**************${RED} TEST ${4} ${1}_${3} Valgrind detected memory leaks!${NC} **************"
    cat ${VALGRING_TEMP} | tail -10
  fi
  if [[ ${total_errors} != 0 ]]; then
    echo -e "**************${RED} TEST ${4} ${1}_${3} Valgrind ERROR SUMMARY returned ${total_errors} errors!${NC} **************"
    cat ${VALGRING_TEMP} | tail -1
  fi
  if [[ ${diff_results} == 0 ]] && [[ ${heaps_blocks_freed} == 0 ]] && [[ ${total_errors} == 0 ]]; then
    echo -e "**************${GREEN} PASSED! ${4} ${1}_${3}${NC} **************"
  fi
}

function execute_and_compare() {
  local num_of_tests=`ls -l ${INPUT_DIR} | grep -i $1 | wc -l`

  for ((i = 1; i <= ${num_of_tests}; i++))
  do
    in=${INPUT_DIR}/${1}${INPUT_POSTFIX}${i}
    out=${TEST_OUTPUT_DIR}${1}${OUTPUT_POSTFIX}${i}

    echo -e "**************${GREEN} Testing ${1}_${i}${NC} **************"
    ${VALGRIND} ${APP_EXEC} < ${in} 1> ${out} 2> ${VALGRING_TEMP}

    compare ${1} ${out} ${i}

    echo -e "**************${GREEN} Testing DEBUG_FLAG_ON ${1}_${i}${NC} **************"
    # Making sure debug mode is not faulted, ignoring the debug messages when comparing output diff
    ${VALGRIND} ${DEBUG_MODE} < ${in} 1> ${out} 2> ${VALGRING_TEMP}

    compare ${1} ${out} ${i} DEBUG_FLAG_ON
  done
}

function main() {
  # Auto detect tests
  local tests=`ls ${INPUT_DIR} | awk -F'_input' '{ print $1 }' | sort --uniq | xargs`

  # In order to deactivate tests use the below array and delete unwanted tests, e.g.-
  # tests=("pop_and_print" "positive_power" "number_of_1_bits" "operand_stack" "duplicate" "plus")

  buildApp

  mkdir -p ${TEST_OUTPUT_DIR}
  for test in ${tests[@]}
  do
    execute_and_compare ${test}
  done
}

main
exit $?
