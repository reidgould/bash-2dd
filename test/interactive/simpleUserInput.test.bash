#! /usr/bin/env bash

set -o errexit
set -o pipefail

if
  read -t 4 -p "input: " usrIn \
  && [[ -n $usrIn ]]
then : # ok
else echo; echo "Did not get input." >&2; exit 1;
fi

echo "Example test output to stdout. got input: $usrIn"
echo "Example test output to stderr." >&2
