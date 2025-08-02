#! /usr/bin/env bash

set -o errexit
set -o pipefail

declare scriptDir="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"

# Source dependencies.
declare frameworkDir="$( cd "$scriptDir/../" ; pwd ; )"
source "$frameworkDir/dependencies.sourceAll.bash"
source "$frameworkDir/src/lib.bash"


# When invoked via a symlink, set different behavior.
declare testMethodsToRun
case "${BASH_SOURCE[0]}" in
  */tdd ) testMethodsToRun="tdd" ;;
  */bdd ) testMethodsToRun="bdd" ;;
  */2dd ) testMethodsToRun="tdd,bdd" ;;
  * ) testMethodsToRun="tdd,bdd" ;;
esac

#todo# Let user define directory to search for tests. Let user define a specific file to test (and set --jobs 1).
declare cmdTag=""
declare numJobs=3
while [[ $# -gt 0 ]]; do
  case "$1" in
    --interactive | -i ) numJobs="1"; recordInput="true"; verbose="true"; shift;;
    --verbose | -v ) verbose="true"; shift;;
    --tag | --tags ) cmdTag="${2/#@/}"; shift 2;;
    --jobs ) numJobs="$2"; shift 2;;
    * ) logError "ERROR IN TEST: Unknown argument: \"$1\"."; exit 4 ;;
  esac
done

if isTruthy "$verbose" && (( numJobs > 1 ))
then logError "Argument \"--verbose\" is only compatible with \"--jobs 1\"."; exit 4;
fi

mkdir -p "/tmp/$USER/2dd/run"
declare runDir
runDir="/tmp/$USER/2dd/run/$(date +%s)"
runDir=$(mktemp -d "$runDir.XXX")
logDebug "runDir=$runDir"
mkdir "$runDir/pipe"

if [[ $testMethodsToRun =~ tdd ]]
then
  #todo# Support user given suffixes so any kind of executable file can run as a test.
  findTestFiles '*.test.bash' > "$runDir/pipe/tddFound"
  touch "$runDir/pipe/bddStepsFound"
  touch "$runDir/pipe/bddFeatureFound"
fi
if [[ $testMethodsToRun =~ bdd ]]
then
  touch "$runDir/pipe/tddFound"
  #todo# Support user given suffixes so any kind of executable file can run as a test.
  findTestFiles '*.test-steps.bash' > "$runDir/pipe/bddStepsFound"
  findTestFiles '*.testSteps.bash' >> "$runDir/pipe/bddStepsFound"
  findTestFiles '*.feature' > "$runDir/pipe/bddFeatureFound"
fi

checkTestFiles < "$runDir/pipe/tddFound" > "$runDir/pipe/tddChecked"

mkdir "$runDir/pipe/bddFeatureFlat.d"
flattenFeatureFiles "$runDir/pipe/bddFeatureFlat.d" \
  < "$runDir/pipe/bddFeatureFound" \
  > "$runDir/pipe/bddFeatureFlat"

sort --field-separator "," --key 3 --version-sort \
  "$runDir/pipe/tddChecked" "$runDir/pipe/bddFeatureFlat" \
  > "$runDir/pipe/all"

declare foundOnly="false"
declare runKey="initial"
declare testFile frontMatter
while IFS=, read -d $'\n' testMethod testFile testFileSlug testFileDisplay
do
  #logDebug "testFile=$testFile"
  declare testOnly=false testSkip=false testTags=""
  #
  case "$testMethod" in
    bdd )
      # Search only "front matter", lines up to the ONLY (because we flattened the test files) "Scenario" keyword in the file.
      # Trim leading space.
      # Return only lines starting with "@".
      frontMatter=$(
          sed -E -e "/^\s*Scenario/Q" -e "s/^\s*//" "$testFile" | grep -E '^@' || :
      )
      #logDebug "frontMatter=$frontMatter"
      #
      parseFrontMatter $frontMatter
      #logDebug "testOnly=$testOnly testSkip=$testSkip testTags=$testTags"
      ;;
    tdd )
      # Search only "front matter", meaning comments and empty lines at the beginning of the file.
      # Trim comment and leading space.
      # Return only lines starting with "@".
      frontMatter=$(
          sed -E -e "/^\s*(#.*)?$/!Q" -e "s/^\s*#\s*//" "$testFile" | grep -E '^@' || :
      )
      #logDebug "frontMatter=$frontMatter"
      #
      parseFrontMatter $frontMatter
      #logDebug "testOnly=$testOnly testSkip=$testSkip testTags=$testTags"
      ;;
  esac
  #
  if [[ $testOnly = true ]]
  then
    foundOnly="true"
    runKey="only"
  elif [[ $testSkip = true ]]
  then
    runKey="skip"
  else
    if [[ -z "$cmdTag" ]]
    then runKey="match"
    else
      # This expansion splits the value in testTags into words by replacing "," with a space and allowing shell word splitting to run. It must not have quotes for this to work.
      if containsElement "$cmdTag" ${testTags//,/ }
      then runKey="match"
      else runKey="skip"
      fi
    fi
  fi
  #
  printf "%s,%s,%s,%s,%s\n" \
    "$runKey" "$testMethod" "$testFile" "$testFileSlug" "$testFileDisplay" \
    >> "$runDir/pipe/allRun"
done < "$runDir/pipe/all"

declare logsDir="$runDir/logs"
#mkdir -p "$logsDir"
mkdir -p "$logsDir/status"
mkdir -p "$logsDir/stdOutErr"
mkfifo "$runDir/logs.fifo"
## Open the FD before because writers are going to be intermittent.
exec {logsFD}<>"$runDir/logs.fifo"

logh1 "Tests"
declare testFileBatch testFileBatches testJobPids=()
touch "$runDir/pipe/allRun"
if (( numJobs == 1))
then
  export logsDir
  # Don't background the test when using one job, so it can be interactive.
  while IFS=, read -d $'\n' runKey testMethod testFile testFileSlug testFileDisplay
  do
    runTest <&3 # Restore the terminal as stdin.
  done 3>&0 < "$runDir/pipe/allRun"
  # Above: Save the terminal input on fd 3.
  # Above: When run in a background job, FD 0 will be /dev/null, not the terminal.
  #
  if isTruthy "$verbose"
  then log; logh2 "Results" # The next thing to print after this is from "logFiles" function.
  fi
elif (( numJobs > 1))
then
  testFileBatches=( $( printf "$runDir/pipe/batch%s\n" $( seq 1 $numJobs ) ) )
  #
  #~# Run "loadBalanceRoundRobin" in background is optional because input and output are both static files.
  #~# Touch files so they exist when job tries to read them if "loadBalanceRoundRobin" hasn't created them yet.
  #~touch "${testFileBatches[@]}"
  # Don't background "loadBalanceRoundRobin" unless we're going to open file descriptors because
  # either the reading process tries to read too early and finds a missing file
  # or it reads after "touch" and sees an empty file and closes it before "loadBalanceRoundRobin" writes.
  loadBalanceRoundRobin "$runDir/pipe/allRun" "${testFileBatches[@]}"
  #
  export runDir logsDir logsFD
  for testFileBatch in "${testFileBatches[@]}"
  do
    while IFS=, read -d $'\n' runKey testMethod testFile testFileSlug testFileDisplay
    do
      runTest < /dev/null
    done < "$testFileBatch" &
    # Above: Background the whole loop to process "testFileBatch" sequentially.
    # Above: Multiple loops start in parallel for each "testFileBatches".
    testJobPids+=( $! )
  done
else
  logError "Invalid number of jobs."
  exit 4
fi

# When multiple jobs run, output test results as they complete.
# In "interactive" mode, the single job is syncronous. "logFiles" is run after all tests, conveniently collecting results at the end.
logFiles <&$logsFD &
#logFiles < "$runDir/logs.fifo" &
declare logFilesPid=$!

if (( ${#testJobPids[@]} > 0 ))
then wait "${testJobPids[@]}"
fi
# "logFilesPid" never exits because we opened "logsFD" in ReadWrite mode.
# Send a sentinel value to tell it to exit now that we know no more log files will be created.
# This is better than killing it because we want it to continue to process all the files buffered in the FIFO.
printf "%s\n" "END_LOG_FILES" >&$logsFD
wait "$logFilesPid"
exec {logsFD}<&-
rm "$runDir/logs.fifo"
#rm -r "$runDir/logs"


# Output logs from failed test scripts.
# FILE exists and has a size greater than zero
if [[ -s "$runDir/pipe/testFailed" ]]
then
  log; log "${tfx[fgRed]}${tfx[invert]}# Failed Test Logs${tfx[off]}"
  while IFS=, read -d $'\n' testFile testFileSlug testFileDisplay
  do
    export logTestStdOutErr="${logsDir}/stdOutErr/${testFileSlug}"
    #
    #log; log "${tfx[fgRed]}${tfx[underline]}## Failure in test: ${testFileDisplay}${tfx[off]}"
    log; log "${tfx[fgRed]}${tfx[underline]}## ${testFileDisplay}${tfx[off]}"
    cat "$logTestStdOutErr" \
      | sed -E "s/(.*)/${tfx[fgRed]}\1${tfx[off]}/"
  done < "$runDir/pipe/testFailed"
fi


log; logh1 "Summary"

# Output info about where to find detailed run data.
#log "To view the output of an individual test, \"cat\" the corresponding file found in the following directory."
log "To see test logs, \"cat\" files in directory:"
log "${logsDir}/stdOutErr"

# Log summary of number pass/fail/skip and total.
declare numberTests="$( cat "$runDir/pipe/all" 2>/dev/null | wc --lines )"
declare numberPassed="$( cat "$runDir/pipe/passed" 2>/dev/null | wc --lines )"
declare numberFailed="$( cat "$runDir/pipe/failed" 2>/dev/null | wc --lines )"
declare numberSkipped="$( cat "$runDir/pipe/skipped" 2>/dev/null | wc --lines )"
log; log "$numberTests tests ran. $numberPassed passed. $numberFailed failed. $numberSkipped skipped."

# Exit nonzero if any tests failed.
if (( numberFailed > 0 ))
then exit 1
fi
