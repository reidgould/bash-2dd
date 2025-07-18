#! /usr/bin/env bash

set -o errexit
set -o pipefail

declare scriptDir="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"

#todo# Find a better way to reference dependencies.
#declare depsDir="$( cd "$scriptDir/../../../" ; pwd ; )"
source "$HOME/.bashrc.sourceAll.bash"
declare frameworkDir="$( cd "$scriptDir/../" ; pwd ; )"
source "$frameworkDir/src/lib.bash"


# When invoked via a symlink, set different behavior.
declare testMethodsToRun
case "${BASH_SOURCE[0]}" in
  */tdd ) testMethodsToRun="tdd" ;;
  */bdd ) testMethodsToRun="bdd" ;;
  */ddd ) testMethodsToRun="tdd,bdd" ;;
  * ) testMethodsToRun="tdd,bdd" ;;
esac

declare cmdTag=""
declare numJobs=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag | --tags ) cmdTag="${2/#@/}"; shift 2;;
    --jobs ) numJobs="$2"; shift 2;;
    * ) logError "ERROR IN TEST: Unknown argument: \"$1\"."; return 4 ;;
  esac
done

mkdir -p "/tmp/$USER/ddd/run"
declare runDir
runDir="/tmp/$USER/ddd/run/$(date +%s)"
runDir=$(mktemp -d "$runDir.XXX")
logDebug "runDir=$runDir"
#todo# implement a "clean" command to 'rm -r "/tmp/$USER/ddd"'

if [[ $testMethodsToRun =~ tdd ]]
then
  #todo# Support user given suffixes so any kind of executable file can run as a test.
  findTestFiles '*.test.bash' > "$runDir/tddFilesFound"
  touch "$runDir/bddStepFilesFound"
  touch "$runDir/bddFeatureFilesFound"
fi
if [[ $testMethodsToRun =~ bdd ]]
then
  touch "$runDir/tddFilesFound"
  #todo# Support user given suffixes so any kind of executable file can run as a test.
  findTestFiles '*.bdd-steps.bash' > "$runDir/bddStepFilesFound"
  findTestFiles '*.feature' > "$runDir/bddFeatureFilesFound"
fi

touch "$runDir/bddFeatureFilesFlat" # In case there is no bdd files to process.
while read featureFile
do
  #todo# Split and flatten feature files into one "Scenario" per file.
  ###### Try csplit?  https://unix.stackexchange.com/questions/263904/split-file-into-multiple-files-based-on-pattern
  #todo# ...
  #todo# Omit comments.
  #todo# Duplicate leading tags in each file.
  #todo# Omit "Feature" and "Rule" sections.
  #todo# Duplicate "Background" section in each file. If "Background" comes after "Scenario" sections start, exit with error.
  #todo# One "Scenario" per each file.
  #todo# Tags that appear after "Scenario" apply to the next Scenario. There should be no steps between a tag and a scenario.
  #todo# Copy steps as is: Given, When, Then, And, But, "*".
  #todo# For "Scenario Outline" or "Scenario Template" keywords, inline "Examples" or "Scenarios" data and output a separate file for each.
  #todo# DocStrings not yet supported. Omit any lines that don't start with a keyword.
  printf "%s\n" "$featureFile" > "$runDir/bddFeatureFilesFlat"
done < "$runDir/bddFeatureFilesFound"

sort "$runDir/tddFilesFound" "$runDir/bddFeatureFilesFlat" > "$runDir/testFilesAll"

declare foundOnly="false"
declare runKey="initial"
declare testFile frontMatter
while read testFile
do
  #logDebug "testFile=$testFile"
  declare testOnly=false testSkip=false testTags=""
  #
  case "$testFile" in
    *.feature )
      testMethod="bdd"
      #
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
    * )
      testMethod="tdd"
      #
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
  printf "%s %s %s\n" "$runKey" "$testMethod" "$testFile" >> "$runDir/testFilesAllRun"
done < "$runDir/testFilesAll"


declare logsDir="$runDir/logs"
#mkdir -p "$logsDir"
mkdir -p "$logsDir/status"
mkdir -p "$logsDir/stdErrOut"
mkfifo "$runDir/logs.fifo"
## Open the FD before because writers are going to be intermittent.
exec {logsFD}<>"$runDir/logs.fifo"

logh1 "Tests"
declare testFileBatch testFileBatches testJobPids=()
declare numberTests=0 numberPassed=0 numberFailed=0 numberSkipped=0
if (( numJobs == 1))
then
  export logsDir
  # Don't background the test when using one job, so it can be interactive.
  runTestJob < "$runDir/testFilesAllRun"
elif (( numJobs > 1))
then
  testFileBatches=( $( printf "$runDir/testFileBatch%s\n" $( seq 1 $numJobs ) ) )
  #
  #~# Run "loadBalanceRoundRobin" in background is optional because input and output are both static files.
  #~# Touch files so they exist when job tries to read them if "loadBalanceRoundRobin" hasn't created them yet.
  #~touch "${testFileBatches[@]}"
  # Don't background "loadBalanceRoundRobin" unless we're going to open file descriptors because
  # either the reading process tries to read too early and finds a missing file
  # or it reads after "touch" and sees an empty file and closes it before "loadBalanceRoundRobin" writes.
  loadBalanceRoundRobin "$runDir/testFilesAllRun" "${testFileBatches[@]}"
  #
  for testFileBatch in "${testFileBatches[@]}"
  do
    # Run in background so multiple jobs can start.
    export runDir logsDir logsFD
    runTestJob < "$testFileBatch" &
    testJobPids+=( $! )
  done
else
  logError "Invalid number of jobs."
  exit 4
fi

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
touch "$runDir/testFilesFailed"
while read testFile
do
  testFileRel="${testFile#$PWD/}"
  testSlug="${testFileRel//\//_}"
  export logTestStdErrOut="${logsDir}/stdErrOut/${testSlug}"
  #
  #log; log "${tfx[fgRed]}${tfx[underline]}## Failure in test: ${testFileRel}${tfx[off]}"
  log; log "${tfx[fgRed]}${tfx[invert]}## Failure in test: ${testFileRel}${tfx[off]}"
  cat "$logTestStdErrOut" \
    | sed -E "s/(.*)/${tfx[fgRed]}\1${tfx[off]}/"
done < "$runDir/testFilesFailed"

log; logh1 "Logs"

# Output info about where to find detailed run data.
log "To view the output of an individual test, \"cat\" the corresponding file found in the following directory."
log "${logsDir}/stdErrOut"

log; logh1 "Summary"

# Log summary of number pass/fail/skip and total.
declare numberTests numberPassed numberFailed numberSkipped
log "$numberTests tests ran. $numberPassed passed. $numberFailed failed. $numberSkipped skipped."

# Exit nonzero if any tests failed.
if (( numberFailed > 0 ))
then exit 1
fi
