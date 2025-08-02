#! /usr/bin/env bash

set -o errexit
set -o pipefail

# Source dependencies.
declare scriptDir="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"
declare frameworkDir="$( cd "$scriptDir/../../" ; pwd ; )"
source "$frameworkDir/dependencies/05-log.bash"

logPass "Assertion 1"
logPass "Assertion 2"
logPass "Assertion 3"
