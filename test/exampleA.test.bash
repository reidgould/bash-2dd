#! /usr/bin/env bash

set -o errexit
set -o pipefail

#todo# Find a better way to reference dependencies.
#declare depsDir="$( cd "$scriptDir/../../../" ; pwd ; )"
source "$HOME/.bashrc.sourceAll.bash"
#declare frameworkDir="$( cd "$scriptDir/../" ; pwd ; )"
declare frameworkDir="/home/$USER/.local/share/bash-2dd"
source "$frameworkDir/src/lib.bash"

sleep 0.1

echo "Example test output to stdout."
log "Example test output to stderr."
#log "BASH_SOURCE=${BASH_SOURCE[0]}"
#log "args=$@"

logPass "Assertion 1"
logPass "Assertion 2"
logPass "Assertion 3"

#exit 1
