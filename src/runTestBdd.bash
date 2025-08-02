#! /usr/bin/env bash

set -o errexit
set -o pipefail

: ${runDir?:Must define variable runDir}
: ${frameworkDir?:Must define variable frameworkDir}
: ${logTestFD?:Must define variable logTestFD}
#
testFile="${1?:Must define argument testFile.}"; shift;

declare scriptDir="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"

# Source dependencies.
declare frameworkDir="$( cd "$scriptDir/../" ; pwd ; )"
source "$frameworkDir/dependencies.sourceAll.bash"
source "$frameworkDir/src/lib.bash"


# Load step functions.
declare -A steps
function step { steps["$2"]="$1"; }
function Given { step "$@" ; }
function When { step "$@" ; }
function Then { step "$@" ; }
while read bddSteps
do
  #logTest "loading file \"$bddSteps\""
  source "$bddSteps"
done < "$runDir/pipe/bddStepsFound"


# Run lines from test file.
declare line matchedFunction skipRest=false testStatus=5
while read line
do
  case $line in
    "" ) : Omit empty line ;;
    \#* ) : Omit comment ;;
    @* ) : Do nothing. ;;
    Feature* | Rule* ) : Omit ;;
    Background* ) logTest "${line}" ;;
    Scenario* | Example* ) logTest "${line}" ;;
    "Scenario Outline"* | "Scenario Template"* ) logTest "${line}" ;;
    Given* | When* | Then* | And* | But* | \** )
      if isTruthy $skipRest
      then logSkip "$line"; continue
      fi
      #
      # Match line with step functions.
      #matchedFunction=true
      matchedFunction="" # Set to empty because it still has the value from last match.
      declare linePart="$(printf "%s" "$line" | sed -E 's/(Given|When|Then|And|But|\*)\s*//')"
      #
      for key in "${!steps[@]}"
      do
        if [[ $linePart =~ ${steps[$key]} ]]
        then
          matchedFunction="$key"
          break
        fi
      done
      if [[ -z $matchedFunction ]]
      then logFail "$line"; logTest "No function pattern matched the step."; exit 1
      fi
      #logTest "matchedFunction=$matchedFunction"
      #
      if
        log; logh3 "\"$line\" $matchedFunction"
        "$matchedFunction" "${BASH_REMATCH[@]:1}"
      then logPass "$line"; testStatus=0
      else logFail "$line"; testStatus=1; skipRest=true
      fi
      ;;
    Examples* | Scenarios* ) logWarning "Statement \"Examples\" or \"Scenarios\" not expected in flattened file. line: \"$line\"." ;;
    \| ) logWarning "Table character not expected in flattened file. line: \"$line\"." ;;
    * ) logWarning "Unrecognized line found in flattened file. line: \"$line\"." ;;
  esac
done < "$testFile"

exit $testStatus
