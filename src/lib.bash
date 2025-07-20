#! /bin/false
# Source this file.

# Usage:
# > findTestFiles '*.test.bash' > "$runDir/testFilesFound"
function findTestFiles {
  : ${1:?Must give arg 1}
  #
  find "$PWD" \
    -mindepth 1 \
    \( \
      -name build \
      -or -name '*.git' \
      -or -name '.git' \
      -or -name dist \
      -or -name node_modules \
      -or -name .npm \
      -or -name jspm_packages \
      -or -name .cache \
      -or -name .yarn \
      -or -name venv \
      -or -name .pytest_cache \
      -or -name __pycache__ \
      -or -name htmlcov \
      -or -name .coverage \
      -or -name '.coverage.*' \
      -or -name .gradle \
      -or -name target \
    \) -prune \
    -or -type f -name "$1" -print \
    | sort
}

# Variables to declare in scope where function is called:
# declare testOnly=false testSkip=false testTags=""
#function parseFrontMatter {
#  while [[ $# -gt 0 ]]; do
#    case "$1" in
#      tdd ) shift;;
#      bdd ) shift;;
#      --only ) testOnly=true; shift ;;
#      --skip ) testSkip=true; shift ;;
#      --tags ) testTags=$2; shift 2;;
#      "" ) shift;;
#      * ) echo "ERROR IN TEST: Unknown front matter: \"$1\"."; return 4 ;;
#    esac
#  done
#}
function parseFrontMatter {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      tdd | bdd | "" ) shift;;
      @only | only ) testOnly=true; shift ;;
      @skip | skip ) testSkip=true; shift ;;
      * ) testTags="$testTags ${1/#@/}"; shift ;;
    esac
  done
}

function runTestJob {
  while read runKey testMethod testFile
  do
    runTest <&3 # Restore the terminal as stdin.
  done 3>&0
  # Above: Save the terminal input on fd 3.
  # Above: When run in a background job, FD 0 will be /dev/null, not the terminal.
}
function runTest {
  : ${runDir?:Must define variable runDir}
  : ${logsDir?:Must define variable logsDir}
  : ${logsFD?:Must define variable logsFD}
  : ${testFile?:Must define variable testFile}
  : ${testMethod?:Must define variable testMethod}
  : ${testFile?:Must define variable runKey}
  #
  case "$runKey" in
    only ) doRun=true ;;
    match )
      if [[ $foundOnly = "true" ]]
      then doRun=false
      else doRun=true
      fi
      ;;
    skip ) doRun=false ;;
  esac
  #
  #logh1 "./${testFile#$PWD/}"
  if [[ $doRun = "true" ]]
  then
    #
    # setup
    declare testRunner
    case "$testMethod" in
      tdd )
        #testRunner="$scriptDir/../src/runTestTdd.bash"
        testRunner=runTestTdd
        ;;
      bdd )
        testRunner="$scriptDir/../src/runTestBdd.bash"
        ;;
    esac
    # ...
    testFileRel="${testFile#$PWD/}"
    testSlug="${testFileRel//\//_}"
    # For testDir, replace "/" with "_" for a flat structure.
    testDir="$runDir/tests/$testSlug"
    mkdir -p "$testDir"
    # ...
    export logTest=$( mktemp "${logsDir}/XXXX" )
    export logTestSub=$( mktemp "${logsDir}/XXXX" )
    export logTestStatus="${logsDir}/status/${testSlug}"
    export logTestStdErrOut="${logsDir}/stdErrOut/${testSlug}"
    touch "$logTest" "$logTestSub"
    exec {logTestFD}<>"$logTest"
    exec {logTestFDSub}<>"$logTestSub"
    #
    # test
    if
      # Run the test in a sub process.
      #todo# INTERACTIVE! (just an alias for "--jobs 1 "and "--verbose"?) (record intput? now it's as easy as an extra "tee".)
      #todo# Verbose mode. Print screen output as it runs. print header when file starts.
      # Warning: Output is lost if redirects use the file name twice like this:  >"$logTestStdErrOut" 2>"$logTestStdErrOut""
      export runDir frameworkDir testFile 
      logTestFD=$logTestFDSub logColor=always \
        "$testRunner" "$testFile" \
          >"$logTestStdErrOut" 2>&1
    then
      logPass "$testFileRel"
      #printf "%s\n" "$testFile" >> "$runDir/testFilesPassed"
    (( ++ numberTests, ++ numberPassed ))
    else
      logFail "$testFileRel"
      printf "%s\n" "$testFile" >> "$runDir/testFilesFailed"
    (( ++ numberTests, ++ numberFailed ))
    fi
    #
    # teardown
    exec {logTestFD}>&-
    exec {logTestFDSub}>&-
    unset logTestFD logTestFDSub
    #
    cat "$logTest" "$logTestSub" > "$logTestStatus"
    rm "$logTest" "$logTestSub"
    printf "%s\n" "$logTestStatus" >&$logsFD
    #
  else
    logSkip "$testFileRel"
    (( ++ numberTests, ++ numberSkipped ))
  fi
}

function loadBalanceRoundRobin {
  declare inFile="${1?:Must give argument inFile}"; shift;
  : "${1?:Must give arguments for output}"
  declare inFD outFile outFD arrayOutFDs=()
  #
  if [[ $inFile == - ]]
  then inFile="/dev/fd/0"
  fi
  #
  ## Open FDs.
  for outFile in "$@"
  do
    exec {outFD}>"$outFile"
    arrayOutFDs+=( $outFD )
  done
  #
  declare outFileIndex argIndex
  outFileIndex=0
  argIndex=1
  while read line
  do
    # Instead of opening the file descriptors ahead of time, we could write with a like like this,
    # but it disrupts streaming capability because it closes the FD, killing any process with it open in read mode.
    #~printf "%s\n" "$line" > "${!argIndex}"
    #
    # "arrayOutFDs" starts at index 0, but args start at index 1.
    outFileIndex=$(( argIndex - 1 ))
    outFD="${arrayOutFDs[$outFileIndex]}"
    printf "%s\n" "$line" >&$outFD
    #
    (( ++ argIndex ))
    if (( argIndex > $# ))
    then argIndex=1 # If argIndex is out of bounds of args, set it back to 1.
    fi
  done < "$inFile"
  #
  # Close FDs.
  for outFD in "${arrayOutFDs[@]}"
  do exec {outFD}>&-
  done
}

function logFiles {
  declare logFileName
  while read logFileName
  do
    if [[ $logFileName = END_LOG_FILES ]]
    then return 0
    else cat "$logFileName" || :
    fi
  done
}

function runTestTdd {
  # Execute the file.
  logTestIndent="  " \
    "$testFile"
  #
}
