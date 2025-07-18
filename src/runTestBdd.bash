#! /usr/bin/env bash

set -o errexit
set -o pipefail

: ${runDir?:Must define variable runDir}
: ${frameworkDir?:Must define variable frameworkDir}
: ${logTestFD?:Must define variable logTestFD}

declare scriptDir="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"

#todo# Find a better way to reference dependencies.
#declare depsDir="$( cd "$scriptDir/../../../" ; pwd ; )"
source "$HOME/.bashrc.sourceAll.bash"
declare frameworkDir="$( cd "$scriptDir/../" ; pwd ; )"
source "$frameworkDir/src/lib.bash"

logTestIndent="  "

# Load files with step implementations.

#todo# Define a way for step files to output "pattern" -> "function" map.
while read bddStepFile
do
  source "$bddStepFile"
done < "$runDir/bddStepFilesFound"

testFile="$1"; shift;

while read line
do
  if [[ "$line" =~ ^Feature|Rule|Scenario|Given|When|Then|And|But ]]
  then logPass "$line"
  else : # Ignore line
  fi
  #todo# Match "Given", "When", and "Then", and other Cucumber/Gherkin statements with functions defined in "$runDir/bddStepFilesFound"
  #todo# Call logPass, logFail, and logSkip based on result of function.
  #todo# Call logSkip for later statements if one fails.
done < "$testFile"

echo "SAMPLE TEST OUTPUT"
exit 9
