#! /bin/false
# Source this file.

# Usage:
# > findTestFiles '*.test.bash' > "$runDir/pipe/testFound"
function findTestFiles {
  : ${1:?Must give arg 1}
  #
  #todo# if fdfind is available, use it instead to take advantage of it's "ignore file" features.
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

function checkTestFiles {
  #
  declare testFile
  while read testFile
  do
    #todo# fail on newlines or commas in testFile name.
    #
    declare testFileRel="${testFile#$PWD/}"
    declare testFileDisplay="$testFileRel"
    declare testFileSlug="${testFileRel//\//_}"
    # Optional to replace ".". It reduces confusion of inaccurate file extensions.
    testFileSlug="${testFileSlug//./_}"
    #
    printf "%s,%s,%s,%s\n" "tdd" "$testFile" "$testFileSlug" "$testFileDisplay"
  done
}

function outputScenario {
  #
  : ${testFile?:Must define variable testFile.}
  : ${scenarioNumber?:Must define variable scenarioNumber.}
  : ${exampleNumber?:Must define variable exampleNumber.}
  : ${flatOutDir?:Must define variable flatOutDir.}
  #
  declare testFileRel testFileDisplay testFileSlug testFileFlat
  testFileRel="${testFile#$PWD/}"
  if (( exampleNumber >= 0))
  then
    testFileDisplay="${testFileRel#$PWD/} (Scenario ${scenarioNumber}, Example ${exampleNumber})"
    testFileSlug="${testFileRel//\//_}_s${scenarioNumber}_e${exampleNumber}"
  else
    testFileDisplay="${testFileRel#$PWD/} (Scenario ${scenarioNumber})"
    testFileSlug="${testFileRel//\//_}_s${scenarioNumber}"
  fi
  # Optional to replace ".". It reduces confusion of inaccurate file extensions.
  testFileSlug="${testFileSlug//./_}"
  testFileFlat="$flatOutDir/$testFileSlug"
  #
  printf "%s\n" "${tagLinesApplyAll[@]}" >> "$testFileFlat"
  printf "%s\n" "${tagLinesApplyScenario[@]}" >> "$testFileFlat"
  printf "%s\n" "${backgroundLines[@]}" >> "$testFileFlat"
  printf "%s\n" "${scenarioLines[@]}" >> "$testFileFlat"
  #
  printf "%s,%s,%s,%s\n" "bdd" "$testFileFlat" "$testFileSlug" "$testFileDisplay"
}
function flattenFeatureFiles {
  # https://cucumber.io/docs/gherkin/reference/
  #
  declare flatOutDir="${1:?Must define argument flatOutDir.}"; shift
  #
  declare -a tagLines
  declare -a tagLinesApplyAll
  declare -a tagLinesApplyScenario
  declare -a backgroundLines
  declare -a scenarioLines
  declare -a scenarioOutlineLines
  #
  declare testFile currentSection exampleNumber
  #
  while read testFile
  do
    #todo# fail on newlines or commas in testFile name.
    # Split and flatten feature files into one "Scenario" per file.
    tagLines=()
    tagLinesApplyAll=()
    tagLinesApplyScenario=()
    backgroundLines=()
    scenarioLines=()
    scenarioOutlineLines=()
    #
    currentSection="None"
    scenarioNumber="-1"
    exampleNumber="-1"
    #
    while read line
    do
      case $line in
        "" ) : Omit empty line ;;
        \#* ) : Omit comment ;;
        @* )
          # Save tags for application when other statements are read.
          tagLines+=( "$line" )
          ;;
        Feature* | Rule* )
          currentSection="freeFormDescription"
          # Omit feature and rule sections from output.
          # Write leading tags in all test files.
          tagLinesApplyAll=( "${tagLinesApplyAll[@]}" "${tagLines[@]}" )
          tagLines=()
          ;;
        Background* )
          # If "Background" comes after "Scenario" sections start, exit with error.
          case "$currentSection" in
            Scenario | "Scenario Outline" | Examples )
              logError "Feature file has \"Background\" after Scenarios or Examples started."
              return 4
              ;;
          esac
          #
          currentSection="Background"
          # Write line in all test files.
          backgroundLines+=( "$line" )
          # Write leading tags in all test files.
          tagLinesApplyAll=( "${tagLinesApplyAll[@]}" "${tagLines[@]}" )
          tagLines=()
          ;;
        Scenario* | Example* )
          # "Example" keyword is equivalent to "Scenario", usually goes with "Rule". Not equivalent to "Examples" which goes with "Scenario Outline".
          currentSection="Scenario"
          #
          # Output one test file per Scenario.
          if (( scenarioNumber >= 0 ))
          then
            outputScenario
            tagLinesApplyScenario=()
            scenarioLines=()
            exampleNumber="-1"
          else
            : # Do nothing. The first time we find this keyword, we have not yet completed parsing a scenario to output.
          fi
          (( ++ scenarioNumber )) || : # Don't crash when number == 0.
          #
          # Write tags in scenario file.
          tagLinesApplyScenario=( "${tagLinesApplyScenario[@]}" "${tagLines[@]}" )
          tagLines=()
          # Write line in test file.
          scenarioLines+=( "$line" )
          ;;
        "Scenario Outline"* | "Scenario Template"* )
          #todo# For "Scenario Outline" or "Scenario Template" keywords, inline "Examples" or "Scenarios" data and output a separate file for each.
          logError "Scenario Outline not implemented."; return 5; #todo# implement
          currentSection="Scenario Outline"
          # Write line in test file.
          #todo# Flatten the "Scenario Outline" prefix to "Scenario"? Or keep it adn match both in run step?
          scenarioOutlineLines+=( "$line" )
          ;;
        Given* | When* | Then* | And* | But* | \** )
          # "\**" matches when line starts with literal "*", and then has more content.
          case "$currentSection" in
            Background )
              # Write line in all test files.
              backgroundLines+=( "$line" )
              ;;
            Scenario )
              # Write line in test file.
              scenarioLines+=( "$line" )
              ;;
            "Scenario Outline" )
              # Write line in test file.
              scenarioOutlineLines+=( "$line" )
              ;;
            freeFormDescription )
              : # Omit line.
              ;;
            * ) logError "Step line found in invalid section of feature file: \"$line\""; return 4
          esac
          ;;
        Examples* | Scenarios* )
          #todo# For "Scenario Outline" or "Scenario Template" keywords, inline "Examples" or "Scenarios" data and output a separate file for each.
          logError "Examples not implemented."; return 5; #todo# implement
          currentSection="Examples"
          ;;
        \| )
          logError "Examples not implemented."; return 5; #todo# implement
          #todo# Use readarray with delim "|", then use a slice expansion to trim the leading and trailing elements.
          if (( exampleNumber >= 0 ))
          then
            #todo# This is an example row. Replace strings in "scenarioOutlineLines", save in "scenarioLines", and output a test file.
            :
          else
            #todo# This is the header row. Set strings to replace in "scenarioOutlineLines".
            :
          fi
          (( ++ exampleNumber )) || : # Don't crash when number == 0.
          ;;
        * )
          case "$currentSection" in
            freeFormDescription ) : Omit description lines ;;
            * ) logError "Invalid line in feature file: \"$line\""; return 4
          esac
          #todo# DocStrings not supported.
          ;;
      esac
    done < <( sed -E -e '/^\s*$/d' -e 's/^\s+//'  "$testFile" )
    # Above: sed removes empty lines and leading whitespace.
    #
    outputScenario
  done
}

# Variables to declare in scope where function is called:
# declare testOnly=false testSkip=false testTags=""
# region #todo# delete?
#function parseFrontMatter {
#  while [[ $# -gt 0 ]]; do
#    case "$1" in
#      tdd ) shift;;
#      bdd ) shift;;
#      --only ) testOnly=true; shift ;;
#      --skip ) testSkip=true; shift ;;
#      --tags ) testTags=$2; shift 2;;
#      "" ) shift;;
#      * ) logError "ERROR IN TEST: Unknown front matter: \"$1\"."; return 4 ;;
#    esac
#  done
#}
# endregion delete?
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

function runTest {
  : ${runDir?:Must define variable runDir}
  : ${logsDir?:Must define variable logsDir}
  : ${logsFD?:Must define variable logsFD}
  : ${testFile?:Must define variable testFile}
  : ${testFileSlug?:Must define variable testFileSlug}
  : ${testFileDisplay?:Must define variable testFileDisplay}
  : ${testMethod?:Must define variable testMethod}
  : ${runKey?:Must define variable runKey}
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
    # For testDir, replace "/" with "_" for a flat structure.
    testDir="$runDir/tests/$testFileSlug"
    mkdir -p "$testDir" "${logsDir}/stdIn" "${logsDir}/stdOutErr"
    # ...
    export logTest=$( mktemp "${logsDir}/XXXX" )
    export logTestSub=$( mktemp "${logsDir}/XXXX" )
    export logTestStatus="${logsDir}/status/${testFileSlug}"
    export logTestStdOutErr="${logsDir}/stdOutErr/${testFileSlug}"
    export logTestStdIn="${logsDir}/stdIn/${testFileSlug}"
    touch "$logTest" "$logTestSub"
    exec {logTestFD}<>"$logTest"
    exec {logTestFDSub}<>"$logTestSub"
    #
    # test
    if
      # Run the test in a sub process.
      (
        export runDir frameworkDir testFile 
        export logTestFD="$logTestFDSub"
        export logColor=always
        export logTestIndent="  "
        #
        ##todo# Record input for interactive mode.
        #if isTruthy "$recordInput"
        #then
        #  exec < <( tee "$logTestStdIn" )
        #  #exec < <( stdbuf -i0 -oL -eL tee "$logTestStdIn" )
        #  #exec < <( stdbuf -i0 -o0 -e0 tee "$logTestStdIn" )
        #fi
        #
        if isTruthy "$verbose"
        then
          log; logh2 "$testFileDisplay"
          exec > >(tee "$logTestStdOutErr") 2>&1
        else
          # Warning: Output is lost if redirects use the file name twice like this:  >"$logTestStdOutErr" 2>"$logTestStdOutErr""
          exec >"$logTestStdOutErr" 2>&1
        fi
        #
        # Run the test.
        case "$testMethod" in
          tdd ) exec "$testFile" ;;
          bdd ) exec "$scriptDir/src/runTestBdd.bash" "$testFile" ;;
        esac
      )
    then
      logPass "$testFileDisplay"
      printf "%s\n" "$testFile" >> "$runDir/pipe/passed"
    else
      logFail "$testFileDisplay"
      printf "%s,%s,%s\n" "$testFile" "$testFileSlug" "$testFileDisplay" >> "$runDir/pipe/failed"
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
    logColor=always logSkip "$testFileDisplay" >"${logsDir}/status/${testFileSlug}" 2>&1
    printf "%s\n" "${logsDir}/status/${testFileSlug}" >&$logsFD
    printf "%s\n" "$testFile" >> "$runDir/pipe/skipped"
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
